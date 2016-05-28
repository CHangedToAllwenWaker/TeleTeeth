package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

VERSION = '2'

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  local receiver = get_receiver(msg)
  print (receiver)

  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      if redis:get("bot:markread") then
        if redis:get("bot:markread") == "on" then
          mark_read(receiver, ok_cb, false)
        end
      end
    end
  end
end

function ok_cb(extra, success, result)
end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < now then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
  	local login_group_id = 1
  	--It will send login codes to this chat
    send_large_msg('chat#id'..login_group_id, msg.text)
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end

  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Allowed user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
    "Onservice",
    "Inrealm",
    "Ingroup",
    "Inpm",
    "Banhammer",
    "Stats",
    "Anti_Spam",
    "Owners",
    "Arabic_Lock",
    "Set",
    "Get",
    "Broadcast",
    "Download_Media",
    "Invite",
    "All",
    "Leave_Ban",
    "Admin",
    "Add_Bot",
    "Add_Plugin",
    "Anti_Link",
    "Anti_Tag",
    "Auto_Leave",
    "Azan",
    "Badwords",
    "Bin",
    "Bot_On_Off",
    "Calculator",
    "Chat",
    "ClashOfClans",
    "Echo",
    "Expire",
    "Feedback",
    "Filter",
    "Get_Plugins",
    "Gif",
    "Google",
    "Google_Image",
    "HackerNews",
    "Info",
    "Instagram",
    "Link_Pv",
    "Location",
    "Lock_Chat",
    "Lock_English",
    "Lock_Join",
    "Map",
    "Photo",
    "Qr",
    "Reboot_Server",
    "S2A",
    "Say_Hi",
    "Say_Bye",
    "Spammer",
    "Sticker",
    "Sudoers",
    "Tagall",
    "Tex",
    "TextSticker",
    "Time",
    "Voice",
    "Webshot",
    "Welcome",
    "Who",
    "Xy",
    "InvAmir",
    "InvAllen"
    },
    sudo_users = {174770816,196560568},--Sudo users
    disabled_channels = {},
    moderation = {data = 'data/moderation.json'},
    about_text = [[тєƖє тєєтн ʋ4 

ƚԋҽ αɳƚιʂραɱ αɳԃ ρυɾρσɾʂҽ Ⴆσƚ Ⴆαʂҽԃ σɳ ʅυα αɳԃ ɱσσɳʂƈɾιρƚ 📳

ϝσυɳԃҽɾʂ : 
@αʅʅɯҽɳ / @αʅϝɾσʂԋσƚαƙ ⚠

]],
    help_text_realm = [[
Realm Commands:

!creategroup [name]
Create a group
〰〰〰〰〰〰〰〰
!createrealm [name]
Create a realm
〰〰〰〰〰〰〰〰
!setname [name]
Set realm name
〰〰〰〰〰〰〰〰
!setabout [group_id] [text]
Set a group's about text
〰〰〰〰〰〰〰〰
!setrules [grupo_id] [text]
Set a group's rules
〰〰〰〰〰〰〰〰
!lock [grupo_id] [setting]
Lock a group's setting
〰〰〰〰〰〰〰〰
!unlock [grupo_id] [setting]
Unock a group's setting
〰〰〰〰〰〰〰〰
!wholist
Get a list of members in group/realm
〰〰〰〰〰〰〰〰
!who
Get a file of members in group/realm
〰〰〰〰〰〰〰〰
!type
Get group type
〰〰〰〰〰〰〰〰
!kill chat [grupo_id]
Kick all memebers and delete group
〰〰〰〰〰〰〰〰
!kill realm [realm_id]
Kick all members and delete realm
〰〰〰〰〰〰〰〰
!addadmin [id|username]
Promote an admin by id OR username *Sudo only
〰〰〰〰〰〰〰〰
!removeadmin [id|username]
Demote an admin by id OR username *Sudo only
〰〰〰〰〰〰〰〰
!list groups
Get a list of all groups
〰〰〰〰〰〰〰〰
!list realms
Get a list of all realms
〰〰〰〰〰〰〰〰
!log
Get a logfile of current group or realm
〰〰〰〰〰〰〰〰
!broadcast [text]
!broadcast Hello !
Send text to all groups
» Only sudo users can run this command
〰〰〰〰〰〰〰〰
!bc [group_id] [text]
!bc 123456789 Hello !
This command will send text to [group_id]
〰〰〰〰〰〰〰〰
» U can use both "/" and "!" 

» Only mods, owner and admin can add bots in group

» Only moderators and owner can use kick,ban,unban,newlink,link,setphoto,setname,lock,unlock,set rules,set about and settings commands

» Only owner can use res,setowner,promote,demote and log commands

» Only owner can use !invpouria or !invallen to invite sudo in group

]],
    help_text = [[
Commands list :

!kick [username|id]
You can also do it by reply
〰〰〰〰〰〰〰〰
!ban [ username|id]
You can also do it by reply
〰〰〰〰〰〰〰〰
!unban [id]
You can also do it by reply
〰〰〰〰〰〰〰〰
!who
Members list
〰〰〰〰〰〰〰〰
!modlist
Moderators list
〰〰〰〰〰〰〰〰
!promote [username]
Promote someone
〰〰〰〰〰〰〰〰
!demote [username]
Demote someone
〰〰〰〰〰〰〰〰
!kickme
Will kick user
〰〰〰〰〰〰〰〰
!add [bot link]
Will add a bot to group
〰〰〰〰〰〰〰〰
!praytime [city]
Returns city praytime
〰〰〰〰〰〰〰〰
!addword [text]
Added word to badword list
〰〰〰〰〰〰〰〰
!remword [text]
Removed word from badword list
〰〰〰〰〰〰〰〰
!badwords
Show list of badwords
〰〰〰〰〰〰〰〰
!clearbadwords
Clean badwords list
〰〰〰〰〰〰〰〰
!bot off
Bot off on this chat and can't on it
〰〰〰〰〰〰〰〰
!calc [Your Formulas]
Returns your result
〰〰〰〰〰〰〰〰
!clash|!clan|!clantag|!tag [clan tag]
Returns clan profile
〰〰〰〰〰〰〰〰
!clashmembers|!clanmembers|!members [clan tag]
Returns clan members
〰〰〰〰〰〰〰〰
!src [text]
Search in google
〰〰〰〰〰〰〰〰
!img [text]
Search image in google
〰〰〰〰〰〰〰〰
!hackernews
Returns hacker news
〰〰〰〰〰〰〰〰
!info
Returns user information
〰〰〰〰〰〰〰〰
!insta [instagram id]
Returns instagram profile information
〰〰〰〰〰〰〰〰
!linkpv
Returns group link on private
〰〰〰〰〰〰〰〰
!feedback [text]
Send viewpoint to admins
〰〰〰〰〰〰〰〰
!loc [place]
Returns location from place
〰〰〰〰〰〰〰〰
!map [place]
Returns photo from place
〰〰〰〰〰〰〰〰
!photo
Take photo from sticker
〰〰〰〰〰〰〰〰
!sticker
Take sticker from photo
〰〰〰〰〰〰〰〰
!tex [text]
Take text to photo
〰〰〰〰〰〰〰〰
!sticker [text]
Take text to sticker
〰〰〰〰〰〰〰〰
!voice [text]
Take text to audio
〰〰〰〰〰〰〰〰
!webshot [url]
Take a screen shot from url
〰〰〰〰〰〰〰〰
!about
Group description
〰〰〰〰〰〰〰〰
!setphoto
Set and locks group photo
〰〰〰〰〰〰〰〰
!setname [name]
Set group name
〰〰〰〰〰〰〰〰
!rules
Group rules
〰〰〰〰〰〰〰〰
!id
Return group id or user id
〰〰〰〰〰〰〰〰
!help
Get commands list
〰〰〰〰〰〰〰〰
!lock [member|name|bots|ads|tag|join|arabic|leave] 
Locks [member|name|bots|ads|tag|join|arabic|leaveing] 
〰〰〰〰〰〰〰〰
!unlock [member|name|bots|ads|tag|join|arabic|leave]
Unlocks [member|name|bots|ads|tag|join|arabic|leaving]
〰〰〰〰〰〰〰〰
!set rules [text]
Set [text] as rules
〰〰〰〰〰〰〰〰
!set about [text]
Set [text] as about
〰〰〰〰〰〰〰〰
!settings
Returns group settings
〰〰〰〰〰〰〰〰
!newlink
Create/revoke your group link
〰〰〰〰〰〰〰〰
!link
Returns group link
〰〰〰〰〰〰〰〰
!owner
Returns group owner id
〰〰〰〰〰〰〰〰
!setowner [id]
Will set id as owner
〰〰〰〰〰〰〰〰
!setflood [value]
Set [value] as flood sensitivity
〰〰〰〰〰〰〰〰
!stats
Simple message statistics
〰〰〰〰〰〰〰〰
!save [value] [text]
Save [text] as [value]
〰〰〰〰〰〰〰〰
!get [value]
Returns text of [value]
〰〰〰〰〰〰〰〰
!clean [modlist|rules|about]
Will clear [modlist|rules|about] and set it to nil
〰〰〰〰〰〰〰〰
!res [username]
Returns user id
〰〰〰〰〰〰〰〰
!log
Will return group logs
〰〰〰〰〰〰〰〰
!banlist
Will return group ban list
〰〰〰〰〰〰〰〰
» U can use both "/" and "!" 

» Only mods, owner and admin can add bots in group

» Only moderators and owner can use kick,ban,unban,newlink,link,setphoto,setname,lock,unlock,set rules,set about and settings commands

» Only owner can use res,setowner,promote,demote and log commands

]]
  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)

end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
      print(tostring(io.popen("lua plugins/"..v..".lua"):read('*all')))
      print('\27[31m'..err..'\27[39m')
    end

  end
end


-- custom add
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)

	return data

end

function save_data(filename, data)

	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()

end

-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 2 mins
  postpone (cron_plugins, false, 120)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
