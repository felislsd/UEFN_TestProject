
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Fortnite.com/Teams }
using { /Fortnite.com/Game }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
game_manager_device := class(creative_device):

    var PlayerMap : [player]int = map{}

    @editable
    var WeaponGranters : []item_granter_device = array{}

    @editable
    var Sentries : []sentry_device = array{}

    @editable
    EndGameDevice : end_game_device = end_game_device{}

    var ElimsToEndGame : int = 0





    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        set ElimsToEndGame = WeaponGranters.Length;
        InitPlayers()
        InitTestMode()
     


    InitPlayers() : void=
        AllPlayers := GetPlayspace().GetPlayers()
        for (Player : AllPlayers, FortCharacter := Player.GetFortCharacter[]): 
            if (set PlayerMap[Player] = 0, WeaponTier := PlayerMap[Player]):
                FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminated)
                GrantWeapon(Player, WeaponTier) #GrantWeapon(Player:player, 0)

    GrantWeapon(Player : player, WeaponTier: int) : void=
        Print("Attempting to grant weapon")
        if (ItemGranter := WeaponGranters[WeaponTier]):
            Print("Granted item to player")
            ItemGranter.GrantItem(Player)

    OnPlayerEliminated(Result : elimination_result) : void=
        Eliminator := Result.EliminatingCharacter
        if (FortCharacter := Eliminator?, EliminatingAgent := FortCharacter.GetAgent[]):
            Print("We need to promote player")

    PromotePlayer(Agent : agent) : void=
        var WeaponTier : int = 0
        if (Player := player[Agent], PlayerWeaponTier := PlayerMap[Player]):
            set WeaponTier = PlayerWeaponTier + 1
            CheckEndGame(Agent, WeaponTier)

        if (Player := player[Agent], set PlayerMap[Player] = WeaponTier): #updates weapon tier
            GrantWeapon(Player, WeaponTier)

    InitTestMode() : void=
        for (Sentry : Sentries):
            Sentry.EliminatedEvent.Subscribe(TestPlayerElimination)

    TestPlayerElimination(Agent : ?agent) : void=
        Print("Sentry eliminated!")
        if (Player := Agent?):
            PromotePlayer(Player)


    #if the player uses all the weapons he wins the game

    CheckEndGame(Player : agent, WeaponTier : int) : void=
        if (WeaponTier >= ElimsToEndGame):
            EndGameDevice.Activate(Player)





npc := class(creative_device):

  
  
               
    #to follow    

    @editable
    RotationProp<private> : creative_prop = creative_prop{}
    @editable
    TranslationProp<private> : creative_prop = creative_prop{}
    @editable
    UnitsPerSecond<private> : float = 100.0
    @editable
    MaxDistanceToPlayer<private> : float = 25.0
    @editable
    AnimationRun<private> : cinematic_sequence_device = cinematic_sequence_device{}
     
    var MaybePlayer<private> : ?player = false 
    var IsMoving<private> : logic = false


    #interaction

    @editable
    ButtonUI : button_device = button_device{}
    TextForButton<localizes> : message = "Bye, bye"

    @editable
    AnimationDance<private> : cinematic_sequence_device = cinematic_sequence_device{}
    TextForDance<localizes> : message = "Dance for me!"

    var PlayerCanvas : canvas = canvas{}


    # getting shot

    @editable 
    var PropManipulator : prop_manipulator_device = prop_manipulator_device{}

 


            


            
    OnBegin<override>()<suspends>:void=
        StorePlayerReference() 
        #interaction
        ButtonUI.InteractedWithEvent.Subscribe(HandleButtonPress)
        #PropManipulator.DestroyEvent.Subscribe(OnPropShot)
        loop:
            RotateToPlayer()
            Sleep(0.0)
            if:
                not IsMoving?
            then:
                set IsMoving = true
                spawn{MoveToPlayer()} #spawn - loop doesn't have to wait for npc to finish moving
                

            
            
                        
    StorePlayerReference() : void =
        if:
            Player : player = Self.GetPlayspace().GetPlayers()[0]
        then:
            set MaybePlayer = option{Player}
            
            
    #cat - look at player
    RotateToPlayer() : void =
        if:
            FortCharacter : fort_character = MaybePlayer?.GetFortCharacter[]
        then:
            PlayerTranslation : vector3 = FortCharacter.GetTransform().Translation
            CurrentTranslation : vector3 = TranslationProp.GetTransform().Translation
            
            #Calculates the rotation to the Player
            VectorToPlayer : vector3 = PlayerTranslation - CurrentTranslation
            RadiansToPlayer : float = ArcTan(VectorToPlayer.X, VectorToPlayer.Y)
            RotationAxis := vector3:
                X := 0.0,
                Y := 0.0,
                Z := -1.0
            NewRotation : rotation = MakeRotation(RotationAxis, RadiansToPlayer) 
            
            #Looks at Player
            if (RotationProp.TeleportTo[CurrentTranslation, NewRotation]) {}
                     
            
            
    MoveToPlayer()<suspends> : void=
        defer: #executed once this function ends
            set IsMoving = false
        if:
            FortCharacter : fort_character = MaybePlayer?.GetFortCharacter[]
        then:
            PlayerTranslation : vector3 = 
                FortCharacter.GetTransform().Translation
            CurrentTranslation : vector3 =
                TranslationProp.GetTransform().Translation
            CurrentRotation : rotation = 
                TranslationProp.GetTransform().Rotation
            # so npc doesn't move vertically
            TranslationToPlayer := vector3:
                X := PlayerTranslation.X
                Y := PlayerTranslation.Y
                Z := CurrentTranslation.Z
            
            DistanceToPlayer : float = 
                Distance(CurrentTranslation, PlayerTranslation)
            
            if:
                #Doesn't move if Player is inside its range.
                DistanceToPlayer > MaxDistanceToPlayer
            then:
                AnimationRun.Play()
                #Moves TranslationProp to the Player's translation
                TranslationProp.MoveTo(
                    TranslationToPlayer,
                    CurrentRotation,
                    DistanceToPlayer / UnitsPerSecond
                ) 
                AnimationRun.Stop()

    

    CreateUI () : canvas =
        Print("CreateUI fun")
        ButtonForCanvas : button_regular = button_regular{DefaultText := TextForButton}
        ButtonToPlayDance : button_loud = button_loud{DefaultText := TextForDance} 
        ButtonForCanvas.OnClick().Subscribe(HandleUIButtonClick)
        ButtonToPlayDance.OnClick().Subscribe(NpcDance)
        NewCanvas : canvas = canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.25, Y := 0.25}, Maximum := vector2{X := 0.25, Y := 0.25}} # (0,0) TL, (1,1) BR
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                    Widget := ButtonForCanvas
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 6.5}
                    SizeToContent := true
                    Widget := ButtonToPlayDance

       


    HandleButtonPress( Agent : agent ) : void =
        if (Player := player[Agent], PlayerUI := GetPlayerUI[Player]):
            set PlayerCanvas = CreateUI()
            PlayerUI.AddWidget(PlayerCanvas, player_ui_slot{InputMode := ui_input_mode.All})
        
            
  

    HandleUIButtonClick(Message : widget_message) : void =
        Player := Message.Player
        if (PlayerUI := GetPlayerUI[Player]):
            PlayerUI.RemoveWidget(PlayerCanvas)


    NpcDance( Message : widget_message) : void =
        AnimationDance.Play()

   # OnPropShot(Agent : agent) : void =







   







  
