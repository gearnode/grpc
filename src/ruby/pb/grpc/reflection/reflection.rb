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
        # binding.irb
        q = EnumeratorQueue.new(self)
        t = Thread.new do
          requests.each do |req|
            case req.message_request
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

        
       # out = V1alpha::ServerReflectionResponse.new
        #call.each_remote_read do |req|
        #  out.valid_host = req.host
        #  out.original_request = req

        #  case req.message_request
        #  when :file_by_filename
        #    puts "file by name request"
        #  when :file_containing_symbol
        #    puts "file containing symbol request"
        #  when :file_containing_extension
        #    puts "file containing extension request"
        #  when :all_extension_numbers_of_type
        #    puts "all extension numbers of type request"
        #  when :list_services
         #   puts "list services request"
        #  else
        #    raise GRPC::InvalidArgument, "invalid message request"
        #  end
       # end
       # out
      end
    end
  end
end
