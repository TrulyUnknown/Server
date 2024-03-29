local module          = {};
local mysql           = require"lapis.db";
local encoder         = library("encode");
local app_helpers     = require"lapis.application";
local http            = require("socket.http");
local json            = require("cjson");
local userinfo        = library("userinfo");

local yield_error     = app_helpers.yield_error;

function module.getFriends(id)
  local ret           = {};
  local ingamep_ret   = mysql.select("gid, player from player_ingame");
  local friends       = http.request(("http://api.roblox.com/users/%d/friends"):format(id));
  friends             = json.decode(friends);

  for index, value in next, friends do
    local toinsert    = {value.Id; value.Username; ingamep_ret[value.Id] and true or false};
    table.insert(toinsert, ingamep_ret[value.Id]);
    table.insert(ret, toinsert);
  end

  return ({success = true, error = "", result = ret});
end

function module.setOnlineGame(id, gid, name)
  local exists_ret    = mysql.select("gid from player_ingame where player=?", id);
  if #exists_ret < 1 then
    mysql.insert("player_ingame", {
      player          = id;
      gid             = gid;
      name            = name;
    });
  else
    mysql.update("player_ingame", {
      player           = id;
      gid              = gid;
      name             = name;
    }, {
      player           = id;
    });
  end

  userinfo.tryCreateUser(id);

  mysql.update("player_info", {
    last_online      = 0;
  }, {
    player           = id;
  });

  return ({success = true, error = ""});
end

function module.goOffline(id, time_ingame)
  mysql.delete("player_ingame", {
    player           = id;
  });
  mysql.update("player_info", {
    last_online      = math.floor(socket.gettime());
    time_ingame      = mysql.raw(("time_ingame+%d"):format(time_ingame));
  }, {
    player           = id;
  });

  return ({success = true, error = ""})
end

return module;
