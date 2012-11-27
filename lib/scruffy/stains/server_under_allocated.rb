# causes:
#   too many players in server

# smell:
#   more players in server than slots allocated

# cleanup:
#   reallocate server

# report:

class ServerUnderAllocated < Stain  
  def clean
    allocator = Allocator.new(@boxes, @pinkies, @servers)
    
    @servers.each do |server|
      if allocator.players_per_slot * server.slots > server.players
        log.warn event: 'server_under_allocated', 
          id: server_id
      end
    end
  end
end