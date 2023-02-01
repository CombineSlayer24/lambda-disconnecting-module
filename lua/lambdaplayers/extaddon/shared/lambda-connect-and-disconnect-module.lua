local player_GetAll = player.GetAll
local color_white = color_white
local rand = math.Rand
local random = math.random

CreateLambdaConvar( "lambdaplayers_cd_showconnectmessage", 1, true, false, false, "If a join message should show in chat when a Lambda Player spawns", 0, 1, { type = "Bool", name = "Show Connect Message", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_cd_connectmessage", "connected to the server", true, false, false, "The message to show when a Lambda Player spawns", nil, nil, { type = "Text", name = "Connect Text", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_cd_allowdisconnecting", 1, true, false, false, "If Lambda Players are allowed to disconnect", 0, 1, { type = "Bool", name = "Allow Disconnecting", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_cd_disconnectmessage", "disconnected from the server", true, false, false, "The message to show when a Lambda Player disconnects", nil, nil, { type = "Text", name = "Disconnect Text", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_cd_disconnecttime", 5000, true, false, false, "The max amount of time it can take for a Lambda to disconnect", 15, 5000, { type = "Slider", decimals = 0, name = "Disconnect Time", category = "Misc" } )

local allowdisconnectline = CreateLambdaConvar( "lambdaplayers_cd_allowdisconnectlines", 1, true, false, false, "If Lambdas are allowed to type a message before they disconnect", 0, 1, { type = "Bool", name = "Allow Disconnect Lines", category = "Text Chat Options" } )
local allowconnectline = CreateLambdaConvar( "lambdaplayers_cd_allowconnectlines", 1, true, false, false, "If Lambdas are allowed to type a message right after they first spawned", 0, 1, { type = "Bool", name = "Allow Connect Lines", category = "Text Chat Options" } )


-- This is all very simple. I don't really need to put a lot of documentation on this


local function Initialize( self )

    self.l_nextdisconnect = CurTime() + rand( 1, GetConVar( "lambdaplayers_cd_disconnecttime" ):GetInt() )  -- The next time until we will disconnect


    -- Very basic disconnecting stuff
    function self:DisconnectState()

        if allowdisconnectline:GetBool() and random( 1, 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then
            self:TypeMessage( self:GetTextLine( "disconnect" ) )
        end
        
        while self:GetIsTyping() do 
            coroutine.yield() 
        end
        
        coroutine.wait( rand( 0.5, 2 ) )

        self:Disconnect()
    end
    
    function self:ConnectedState()
        if allowconnectline:GetBool() and random( 1, 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then
            self:TypeMessage( self:GetTextLine( "connect" ) )
        end
        
        while self:GetIsTyping() do 
            coroutine.yield() 
        end

        if self:GetState() == "ConnectedState" then self:SetState( "Idle" ) end
    end

    -- Leave the game
    function self:Disconnect()
    
        for k, ply in ipairs( player_GetAll() ) do
            LambdaPlayers_ChatAdd( ply, self:GetDisplayColor( ply ), self:GetLambdaName(), color_white,  " " .. GetConVar( "lambdaplayers_cd_disconnectmessage" ):GetString() )
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
