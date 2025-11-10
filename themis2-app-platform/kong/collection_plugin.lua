local servicer = kong.client.get_consumer()
if servicer then
    kong.service.request.set_header("collection", "/servicers/" .. servicer.username)
end
