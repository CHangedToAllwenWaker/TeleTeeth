do
local function run(msg, matches)
  local url = "http://latex.codecogs.com/png.download?".."\\dpi{800}%20\\LARGE%20"..matches[1]
  local receiver = get_receiver(msg)
  local file = download_to_file(url,'text.webp')
      send_document('chat#id'..msg.to.id, file, ok_cb , false)
end

return {
  description = "text to sticker",
  usage = {
    "!sticker [text]"
  },
  patterns = {
    "^[!/#]sticker (.+)$"
  },
  run = run
}

end
