require 'socket'
require 'bindata'

module CPower
  class QueryNetworkSettingsSubPacket < BinData::Record
    endian :little

    uint8 :query, value: 0x01
  end

  class PacketBase < BinData::Record
    QUERY_NETWORK_SETTINGS_COMMAND_CODE = 0x3C
    RESET_APP_COMMAND_CODE = 0xFE

    endian :little
    uint32 :control_id
    uint16 :network_data_length, value: lambda { packet_data.num_bytes + 2 }
    skip length: 2

    struct :packet_data, read_length: lambda { network_data_length - 2 } do
      uint8 :packet_type
      uint8 :command_type
      uint8 :card_id
      uint8 :command_code
      bit8 :confirmation_mark

      string :sub_packet, read_length: lambda { network_data_length - 7 }
    end

    uint16 :crc, value: lambda { packet_data.to_binary_s.bytes.inject(&:+) }
  end

  class NetworkSettingsSubPacket < BinData::Record
    endian :little

    uint8 :success
    uint32 :ip_address
    uint32 :gateway
    uint32 :netmask
    uint16be :port
    uint32 :network_id
  end

  class ExternalCallPacketBase < BinData::Record
    endian :little
    uint32 :control_id
    uint16 :network_data_length, value: lambda { packet_data.num_bytes + 2 }
    skip length: 2

    struct :packet_data, read_length: lambda { network_data_length - 2 } do
      uint8 :packet_type
      uint8 :command_type
      uint8 :card_id
      uint8 :protocol_code, value: 0x7B
      bit8 :confirmation_mark

      uint16 :packet_data_length, value: lambda { sub_packet.length }
      uint8 :packet_number
      uint8 :last_packet_number

      string :sub_packet, read_length: :packet_data_length
    end

    uint16 :crc, value: lambda { packet_data.to_binary_s.bytes.inject(&:+) }
  end

  class SetWindowSubPacket < BinData::Record
    endian :big
    uint8 :command_code, value: 0x01

    uint8 :number, value: lambda { windows.length }
    array :windows, initial_length: :number do
      endian :big
      uint16 :x
      uint16 :y
      uint16 :width
      uint16 :height
    end
  end

  class SetWindowTextSubPacket < BinData::Record
    endian :little

    uint8 :command_code, value: 0x02
    uint8 :window_number
    uint8 :mode
    uint8 :alignment
    uint8 :speed
    uint16 :stay_time
    string :text
  end

  class SimpleImageFormat < BinData::Record
    endian :little

    uint16 :identify, value: 0x3149

    uint16 :width
    uint16 :height

    uint8 :property

    skip length: 1

    array :r, type: :uint8, initial_length: lambda { bytes_per_row * height }
    array :g, type: :uint8, initial_length: lambda { bytes_per_row * height }
    array :b, type: :uint8, initial_length: lambda { bytes_per_row * height }

    def bytes_per_row
      (width / 8).ceil
    end
  end

  class SetWindowImageSubPacket < BinData::Record
    endian :big
    uint8 :command_code, value: 0x03
    uint8 :window_number
    uint8 :mode
    uint8 :speed
    uint16 :stay_time
    uint8 :image_format
    uint16 :x
    uint16 :y

    string :image_data
  end

  class ResetGlobalDisplayAreaSubPacket < BinData::Record
    endian :little
    uint8 :command_code, value: 0x0c

    bit1 :save_to_flash, value: 1
    bit7 :reserved1, value: 0

    uint8 :number, value: 0

    bit1 :synchronous, value: 1
    bit7 :reserved2, value: 0

    uint16 :retention, value: 0
  end

  class ClearFlashDataSubPacket < BinData::Record
    endian :little
    uint8 :command_code, value: 0x07

    uint8 :clear_flash_flag, value: 1
    skip length: 2
  end

  class LedController
    def initialize(type, ip, port)
      @type, @ip, @port = type, ip, port
    end

    def connect
      @socket = Socket.new Socket::AF_INET, Socket::SOCK_STREAM
      @socket.connect Socket.pack_sockaddr_in(@port, @ip)
    end

    def disconnect
      @socket.close
    end

    def restart_app
      assert_socket

      request_packet = PacketBase.new(
        control_id: 0xFFFFFFFF,
        packet_data: {
          packet_type: 0x68,
          command_type: 0x32,
          card_id: 0xFF,
          command_code: PacketBase::RESET_APP_COMMAND_CODE,
        }
      )

      request_packet.write(@socket)
    end

    def play_storied_program
      send_external_call_packet(BinData::Uint8.new(0x6))
    end

    def query_network_params
      assert_socket

      request_packet = PacketBase.new(
        control_id: 0xFFFFFFFF,
        packet_data: {
          packet_type: 0x68,
          command_type: 0x32,
          card_id: 0xFF,
          command_code: PacketBase::QUERY_NETWORK_SETTINGS_COMMAND_CODE,
          sub_packet: QueryNetworkSettingsSubPacket.new.to_binary_s
        }
      )

      request_packet.write(@socket)
      response_packet = PacketBase.new
      response_packet.read(@socket)

      NetworkSettingsSubPacket.read(response_packet.packet_data.sub_packet)
    end

private
    def send_external_call_packet(sub_packet)
      request_packet = ExternalCallPacketBase.new(
        control_id: 0xFFFFFFFF,
        packet_data: {
          packet_type: 0x68,
          command_type: 0x32,
          card_id: 0xFF,
          sub_packet: sub_packet.to_binary_s
        }
      )
      request_packet.write(@socket)
      @socket.flush
    end

    def assert_socket
      raise "Socket is not ready, call connect before sending any command" if @socket.nil?
    end

public

    def reset_global_display_area
      assert_socket

      sub_packet = ResetGlobalDisplayAreaSubPacket.new
      send_external_call_packet(sub_packet)
    end

    def setup_windows(args)
      assert_socket

      sub_packet = SetWindowSubPacket.new( args )
      send_external_call_packet(sub_packet)
    end

    def set_window_text(args)
      assert_socket

      sub_packet = SetWindowTextSubPacket.new(args)
      send_external_call_packet(sub_packet)
    end

    def set_window_image(args)
      assert_socket

      sub_packet = SetWindowImageSubPacket.new(args)
      send_external_call_packet(sub_packet)
    end

    def clear_flash_data
      assert_socket

      sub_packet = ClearFlashDataSubPacket.new
      send_external_call_packet(sub_packet)
    end

    def to_s
      "CPower LedController #{@type}@#{@ip}:#{@port}"
    end
  end
end
