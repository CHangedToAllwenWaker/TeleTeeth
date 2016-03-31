do
local function run(msg, matches)
  local url = "http://tts.baidu.com/text2audio?lan=en&ie=UTF-8&text="..matches[1]
  local receiver = get_receiver(msg)
  local file = download_to_file(url,'text.ogg')
      send_audio('chat#id'..msg.to.id, file, ok_cb , false)
    string.gsub(""," ",".")
end

return {
  description = "text to voice",
  usage = {
    "!voice [text]"
  },
  patterns = {
    "^[!/#]voice (.+)$"
  },
  run = run
}


end