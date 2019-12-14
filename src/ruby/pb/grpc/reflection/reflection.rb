# REQUIRED FOR Google::Protobuf::FileDescriptorProto
require 'protobuf'
require 'google/protobuf/descriptor.pb'


require 'grpc'
require 'grpc/reflection/v1alpha/reflection_services_pb'
require 'grpc/errors'

module Grpc
  module Reflection
    class Reflect < V1alpha::ServerReflection::Service
      def initialize(server)
        @server = server
      end

      def server_reflection_info(requests)
        q = EnumeratorQueue.new(self)
        t = Thread.new do
          requests.each do |req|
            case req.message_request
            when :file_containing_symbol
              service_name = req.file_containing_symbol
              services = @server.send(:rpc_handlers).map { |_, h| h.owner }.uniq
              service = services.find { |service| service.service_name == service_name }
              if service.nil?
                resp = V1alpha::ServerReflectionResponse.new(
                  valid_host: req.host,
                  original_request: req,
                  error_response: V1alpha::ErrorResponse.new(
                    error_code: 5, # NOT FOUND CODE
                    error_message: "Symbol not found: #{service_name}",
                  )
                )
                q.push(resp)
              else
                Google::Protobuf::FileDescriptorProto
                resp = V1alpha::ServerReflectionResponse.new(
                  valid_host: req.host,
                  original_request: req,
                  file_descriptor_response: V1alpha::FileDescriptorResponse.new(
                    file_descriptor_proto: ['ServerReflectionInfo'] #service.rpc_descs.map { |method, _| method.to_s }
                  )
                )
                q.push(resp)
                puts "#" * 70
                puts resp
                puts "#" * 70
              end
            when :list_services
              resp = V1alpha::ServerReflectionResponse.new(
                valid_host: req.host,
                original_request: req,
                list_services_response: V1alpha::ListServiceResponse.new(
                  service: @server.send(:rpc_handlers).map do |_, handler|
                    handler.owner.service_name
                  end.uniq.map { |x| V1alpha::ServiceResponse.new(name: x) }
                )
              )
              q.push(resp)
            end
            Thread.pass
          end
          q.push(self)
        rescue StandardError => e
          q.push(e)
          raise e
        end
        t.priority = -2
        q.each_item
      end
    end
  end
end
