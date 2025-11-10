local servicer = kong.client.get_consumer()
if servicer then
    kong.service.request.set_header("Fiware-Service", "themis2")
    kong.service.request.set_header("Fiware-ServicePath", "/servicers/" .. servicer.username)
end
