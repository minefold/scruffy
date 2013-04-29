# # causes:
# #   too many players in server
#
# # smell:
# #   more players in server than slots allocated
#
# # cleanup:
# #   reallocate server
#
# # report:
#
# class ServerUnderAllocated < Stain
#   include StainWatcher
#
#   stain :server_under_allocated
#
#   # TODO remove hardcoded reference to TF2
#   TF2 = '50bec3967aae5797c0000004'
#
#   def affected_ids
#     @servers.select do |server|
#       player_slots_available =
#         (server.slots || 1) * allocator.players_per_slot
#
#       (server.funpack != TF2) && (server.players.size > player_slots_available)
#     end.ids
#   end
#
#   def stain_gone(stain_id)
#     log.info event: 'server_allocated_ok', id: stain_id
#   end
#
#   def check_stain(stain)
#     server = @servers.find_id(stain.id)
#     required = allocator.slots_required(server.players.size)
#     server_slots = (server.slots || 1)
#
#     slot_difference = Math.log(required, 2) - Math.log(server_slots, 2)
#
#     if stain.duration > 10 * 60 or slot_difference > 1
#       log.warn event: 'server_under_allocated',
#         id: stain.id,
#         action: 'reallocating',
#         slots: server_slots,
#         required: required
#
#       @servers.reallocate!(stain.id, required, "Optimizing server. Please reconnect in 30 seconds")
#       forget stain.id
#
#     else
#       log.info event: 'server_under_allocated',
#         id: stain.id,
#         duration: stain.duration,
#         slots: server_slots,
#         required: required
#     end
#   end
# end