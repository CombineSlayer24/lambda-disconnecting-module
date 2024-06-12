local player_GetAll = player.GetAll
local color_white = color_white
local rand = math.Rand
local random = math.random
local string_Explode = string.Explode
local tonumber = tonumber

CreateLambdaConvar( "lambdaplayers_cd_showconnectmessage", 1, true, false, false, "If a join message should show in chat when a Lambda Player spawns", 0, 1, { type = "Bool", name = "Show Connect Message", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_cd_connectmessage", "connected to the server", true, false, false, "The message to show when a Lambda Player spawns", nil, nil, { type = "Text", name = "Connect Text", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_cd_allowdisconnecting", 1, true, false, false, "If Lambda Players are allowed to disconnect", 0, 1, { type = "Bool", name = "Allow Disconnecting", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_cd_disconnectmessage", "disconnected from the server", true, false, false, "The message to show when a Lambda Player disconnects", nil, nil, { type = "Text", name = "Disconnect Text", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_cd_disconnecttime", 5000, true, false, false, "The max amount of time it can take for a Lambda to disconnect", 15, 5000, { type = "Slider", decimals = 0, name = "Disconnect Time", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_cd_specialdisconnectmessage", "left the game", true, false, false, "The message to show when a Lambda Player gets a special disconnection", nil, nil, { type = "Text", name = "Special Disconnect Text", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_cd_specialdisconnecttextcolor", "255 255 255", true, false, false, "The the color for special disconnect messages\nAlt colors:\n204, 204, 204\n153, 255, 153", nil, nil, { type = "Text", name = "Specail Disconnect Text Color", category = "Misc" } )

local allowdisconnectline = CreateLambdaConvar( "lambdaplayers_cd_allowdisconnectlines", 1, true, false, false, "If Lambdas are allowed to type a message before they disconnect", 0, 1, { type = "Bool", name = "Allow Disconnect Lines", category = "Text Chat Options" } )
local allowconnectline = CreateLambdaConvar( "lambdaplayers_cd_allowconnectlines", 1, true, false, false, "If Lambdas are allowed to type a message right after they first spawned", 0, 1, { type = "Bool", name = "Allow Connect Lines", category = "Text Chat Options" } )
local specialdisconnectmsgchance = CreateLambdaConvar( "lambdaplayers_cd_specialdisconnectmsgchance", 20, true, false, false, "Chance for special disconnect messages to show up instead of the custom disconnection message", 0, 100, { type = "Slider", decimals = 0, name = "Special Disconnect Message Chance", category = "Text Chat Options" } )
local specialinstakickmsgchance = CreateLambdaConvar( "lambdaplayers_cd_specialinstakickmsgchance", 0, true, false, false, "Chance for Lambdas to be instantly disconnect when joining", 0, 100, { type = "Slider", decimals = 0, name = "Instant Disconnect Chance", category = "Text Chat Options" } )

-- This is all very simple. I don't really need to put a lot of documentation on this

local customDisconnectMessage = GetConVar("lambdaplayers_cd_specialdisconnectmessage"):GetString()
local specialDisconnectMsg = {
    { msg = customDisconnectMessage .. " (Timed Out)", chance = 50 },
    { msg = customDisconnectMessage .. " (Client dropped from server)", chance = 25 },
    { msg = customDisconnectMessage .. " (Steam auth ticket has been canceled)", chance = 20 },
    { msg = customDisconnectMessage .. " (Kicked from server)", chance = 20 },
    { msg = customDisconnectMessage .. " (Client not connected to Steam)", chance = 10 },
    { msg = customDisconnectMessage .. " (Invalid STEAM UserID Ticket)", chance = 8 },
    { msg = customDisconnectMessage .. " (VAC banned from secure server)", chance = 5 },
}

local specialRejectMsg = {
    { msg = customDisconnectMessage .. " (Client is banned from the server)", chance = 30 },
    { msg = customDisconnectMessage .. " (Client dropped from server)", chance = 25 },
    { msg = customDisconnectMessage .. " (This Steam account does not own this game)", chance = 25 },
    { msg = customDisconnectMessage .. " (An issue with your computer is blocking the VAC system)", chance = 20 },
    { msg = customDisconnectMessage .. " (Client failed auth session for unknown reason)", chance = 10 },
    { msg = customDisconnectMessage .. " (VAC Banned from server)", chance = 5 },
}

-- Really scuffed way on getting randomized messages
local function GetRandomDisconnectMessage( msgType )
    local msgTable = {}
    if msgType == "disconnect" then
        msgTable = specialDisconnectMsg
    elseif msgType == "rejectConnection" then
        msgTable = specialRejectMsg
    else
        return "" -- Return empty string if an invalid msgType is provided
    end

    -- Combine both chances
    local totalChance = 0
    for _, msgData in ipairs( msgTable ) do
        totalChance = totalChance + msgData.chance
    end

    -- Randomly select a message based on their combined chances
    local randNum = random( 1, totalChance )
    local cumulativeChance = 0

    for _, msgData in ipairs( msgTable ) do
        cumulativeChance = cumulativeChance + msgData.chance
        if randNum <= cumulativeChance then
            return msgData.msg
        end
    end
end

local function GetDisconnectColor()
    local colorValues = string_Explode( " ", GetConVar( "lambdaplayers_cd_specialdisconnecttextcolor" ):GetString() )
    return Color( tonumber( colorValues[ 1 ] ), tonumber( colorValues[ 2 ] ), tonumber( colorValues[ 3 ] ) )
end


local function Initialize( self )

    self.l_nextdisconnect = CurTime() + rand( 1, GetConVar( "lambdaplayers_cd_disconnecttime" ):GetInt() )  -- The next time until we will disconnect

    -- Very basic disconnecting stuff
    function self:DisconnectState()

        -- If the speical disconnect message isn't picked, use default disconnect message
        -- and colors.
        local disconnectMessage = GetConVar( "lambdaplayers_cd_disconnectmessage" ):GetString()
        local messageColor = color_white
        local isSpecialDisconnetMsg = false

        if random( 1, 100 ) <= specialdisconnectmsgchance:GetInt() then 
            isSpecialDisconnetMsg = true
            messageColor = GetDisconnectColor()
            disconnectMessage = GetRandomDisconnectMessage( "rejectConnection" )
            print("Triggered")
        end

        if allowdisconnectline:GetBool() and !isSpecialDisconnetMsg and random( 1, 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then
            self:TypeMessage( self:GetTextLine( "disconnect" ) )
        end
        
        while self:GetIsTyping() do 
            coroutine.yield() 
        end
        
        coroutine.wait( rand( 0.5, 2 ) )

        self:Disconnect( disconnectMessage, messageColor )
    end
    
    function self:ConnectedState()

        -- If the speical disconnect message isn't picked, use default disconnect message
        -- and colors.
        local disconnectMessage = "I got banned or something"
        local messageColor = color_white
        local isInstaDisconnecting = false
    
        if random( 1, 100 ) <= specialinstakickmsgchance:GetInt() then 
            isInstaDisconnecting = true
            messageColor = GetDisconnectColor()
            disconnectMessage = GetRandomDisconnectMessage( "rejectConnection" )
        end
    
        if allowconnectline:GetBool() and !isInstaDisconnecting and random( 1, 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then
            self:TypeMessage( self:GetTextLine( "connect" ) )
        end
    
        if isInstaDisconnecting then
            self:Disconnect( disconnectMessage, messageColor ) -- Pass the actual message here
        end
        
        while self:GetIsTyping() do 
            coroutine.yield() 
        end
    
        if self:GetState() == "ConnectedState" then self:SetState( "Idle" ) end
    end

    -- Leave the game
    function self:Disconnect(disconnectMessage, messageColor)
        local customDisconnectMessage = GetConVar( "lambdaplayers_cd_specialdisconnectmessage" ):GetString()
    
        for k, ply in ipairs( player_GetAll() ) do
            LambdaPlayers_ChatAdd( ply, self:GetDisplayColor( ply ), self:GetLambdaName(), messageColor, " " .. disconnectMessage )
        end
    
        self:Remove()
    end

end

-- Handle connect message
local function AIInitialize( self )

    if GetConVar( "lambdaplayers_cd_showconnectmessage" ):GetBool() then 
        for k, ply in ipairs( player_GetAll() ) do
            LambdaPlayers_ChatAdd( ply, self:GetDisplayColor( ply ), self:GetLambdaName(), color_white,  " " .. GetConVar( "lambdaplayers_cd_connectmessage" ):GetString() )
        end
    end

    self:SetState( "ConnectedState" )

end

local function Think( self )
    if CLIENT then return end

    if CurTime() > self.l_nextdisconnect then

        if GetConVar( "lambdaplayers_cd_allowdisconnecting" ):GetBool() then
            self:SetState( "DisconnectState" )
            self:CancelMovement()
        end
        
        self.l_nextdisconnect = CurTime() + rand( 1, GetConVar( "lambdaplayers_cd_disconnecttime" ):GetInt() ) 
    end

end

hook.Add( "LambdaOnThink", "lambdadisconnecting_think", Think )
hook.Add( "LambdaAIInitialize", "lambdadisconnecting_AIinit", AIInitialize )
hook.Add( "LambdaOnInitialize", "lambdadisconnecting_init", Initialize )
