/**
 * CHANGE LOG SHIN SHOP MADED BY 13 DEVELOPER ~~
 * ** contacts **
 * Email: qwerty124563@gmail.com
 * GitHub: github.com/13dev
 *
 * ** Change log **
 * * 1.0 
 * - Add n vault to store points by steam id
 * - Add read config to read the models by ini
 * - bug fixes on read config
 * - add trim
 * - remove bored vars on read_config
 * - precache models
 * - add g_szFolderModel to store/find models!
 * - thanks **black rose ** for the help in tries / array <3
 *
 * * 1.1
 * - fix save skins method
 * - fix load skins
 * - fix the cur_weapon bug in two for's!
 * - clean code
 * - add function Explode String to separete string by delimiter
 * - add callback to menu to desactivate a item i already bought
 * - change the weapon id to ex: weapon_ak47
 * - change the cur_weapon to Ham_Item_Deploy, muchhh fasterrrrrrrrr
 * - add points to the system
 * - add menu to buy weapon
 * - Method GivePoints to admin give points a an user
 * - add menu to sell weapons
 * - add Colorchat and g_szPrefix
 * - create to methods Load Points / Save points to store player points
 * - add define PERCENT_SALE to store percentage of points the player recive after sell skin
 *
 * * 1.2
 * - add option to donate points
 * - add message mode "quantidade_de_pontos"
 * - creat var ghPlayerToReciveDonate to store id of player to recive donate
 * - add more commands in g_szCommandsMenu
 * - add min donate
 * - remove donator in menu of donations
 * - fix portuguese ty ** DaNgEr <3 **
 * - add client_cmd(id, "lastinv;lastinv") on change skin
 * - remove blanks spaces LOL
 * - change  <> dhudmessage to [] ty  ** DaNgEr **
 * - Fixed bug of player donate points to himself
 *
 * * 1.3
 * - Add translation
 * - removed object ghPlayerVault
 * - fix nvault_close
 * - change key Pontos
 * - Duplicate lastinv // client_cmd("lastinv;lastinv")
 * - Change nvault to fvault .. DONE!
 * - add max points
 * 
 * * 1.4
 *  - Fix Show spec info
 *  - fix show ads
 *
 * * 1.5
 *  - add API
 */


#include <amxmodx>
#include <amxmisc>
#include <fvault>
#include <colorchat>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <dhudmessage>


#define VERSION "1.4.15"
#define INI_FILENAME "skins.ini"
#define MENU_TITLE  "[DANGER GAMING SHOP]"
#define PERCENT_SALE 65
#define MIN_DONATION 2
#define MAX_POINTS 10000
#define MAX_PLAYERS 32
#define MIN_PLAYERS 6

enum enumSkin {
    _WEAPONID[32],
    _FILENAME[128],
    _NAME[32],
    _POINTS
}

new Trie: ghSkinInformation;
new Array: ghAllSkins;
new Array: ghPlayerSkins[33];
new ghPlayerPoints[33];
new ghPlayerToReciveDonate;

static const g_szCommandsMenu[][] = {
    "say /loja",
    "say /shop",
    "say /skins",
    "say loja",
    "say shop",
    "say skins",
    "say_team /loja",
    "say_team /shop",
    "say_team /skins",
    "say_team loja",
    "say_team shop",
    "say_team skins"
};

static const g_szPrefix[] = "^4[DANGER GAMING]^1";
new const g_vault[] = "skinshop";

new g_iK, g_TimeBetweenAds;
new const g_ChatAdvertise[ ][ ] = {
    "%s Escreve^4 /shop^1 para comprares skins.",
    "%s Mata os teus inimigos para receberes pontos.",
    "%s Escreve^4 /skins^1 acessares ao menu de skins."
}

new bool:g_bRoundEnded
new Point_Kill, 
Point_Hs, 
Point_Suicide, 
Point_dieHs,
Point_dieKill,
Point_ExplodeBomb,
Point_Plant,
Point_dieHe,
Point_KillHe,
Point_dieKnife,
Point_KillKnife,
Point_falled,
Point_teamWin,
Point_teamLost

public plugin_init() {
    register_plugin(MENU_TITLE, VERSION, "13 Developer");

    //register say commands
    static i;
    for(i = 0; i < sizeof( g_szCommandsMenu ); i++ )
    {
        register_clcmd( g_szCommandsMenu[ i ], "MainMenu" );
    }

    RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
    register_event( "DeathMsg", "eDeathMsg", "a" );
    register_event( "SendAudio", "TerroristsWin", "a", "2&%!MRAD_terwin" );
    register_event( "SendAudio", "CounterTerroristsWin", "a", "2&%!MRAD_ctwin" );
    register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );

    register_concmd( "sp_give_points", "GivePoints", ADMIN_BAN, "<nome, #userid, authid> <pontos>" );
    register_concmd( "sp_remove_points", "RemovePoints", ADMIN_BAN, "<nome, #userid, authid> <pontos>" );

    g_TimeBetweenAds = register_cvar( "time_between_ads", "300.0" );
    Point_Kill = register_cvar("Points_kill", "1"); // Points That You Get Per Normal Kill
    Point_Hs = register_cvar("Points_kill_hs","2");// Points That You Get Per HS Kill
    Point_Suicide = register_cvar("Points_suicide","1"); // Points That You Lose Per Suicide
    Point_dieKill = register_cvar("Point_dieKill","1");  // Points lose on die
    Point_dieHs = register_cvar("Point_dieHs","2"); // Points lose on die by hs
    Point_Plant = register_cvar("Point_Plant","2"); // Points win on plant bomb
    Point_ExplodeBomb = register_cvar("Point_ExplodeBomb","2"); // Points win on explode bomb
    Point_dieHe = register_cvar("Point_dieHe","4");
    Point_KillHe = register_cvar("Point_KillHe","6");
    Point_dieKnife = register_cvar("Point_dieKnife","4");
    Point_KillKnife = register_cvar("Point_KillKnife","6");
    Point_Suicide = register_cvar("Point_Suicide","3");
    Point_falled = register_cvar("Point_falled","3");
    Point_teamWin = register_cvar("Point_teamWin","2");
    Point_teamLost = register_cvar("Point_teamLost","2");

    register_clcmd("Quantidade_de_pontos", "DonatePoints");
    register_dictionary_colored("skinshop.txt");
}

public plugin_natives( )
{
    register_library( "skinshop" )
    
    register_native( "getpoints", "_getpoints" )
    register_native( "setpoints", "_setpoints" )
}

/**
 * API
 */
public _getpoints( plugin, params )
{
    if( params != 1 )
    {
        return 0;
    }
    
    new id = get_param( 1 );
    if( !id )
    {
        return 0;
    }
    
    return ghPlayerPoints[ id ]
}

public _setpoints( plugin, params )
{
    if( params != 2 )
    {
        return -1;
    }
    
    new id = get_param( 1 );
    new value = get_param( 2 );

    if( !id  || !value)
    {
        return -1;
    }

    ghPlayerPoints[ id ] = value;

    SavePoints(id);
    
    return ghPlayerPoints[ id ];
}

public ChatAdvertisements( )
{
    new Players[ MAX_PLAYERS ], iNum, i
    get_players( Players, iNum, "ch" );
    
    for( --iNum; iNum >= 0; iNum-- )
    {
        i = Players[ iNum ];

        if( is_user_connected( i ) )
        {
            client_print_color( i, print_chat, g_ChatAdvertise[ g_iK ], g_szPrefix );
        }
    }
    
    g_iK++;
    
    if( g_iK >= sizeof g_ChatAdvertise )
        g_iK = 0;
}

stock AddSkinToPlayer(id, SkinID, SaveToVault = 1) {

    if ( PlayerHasSkin(id, SkinID) )
        return 0;

    if ( ! IsSkinIDValid(SkinID) )
        return 0;

    ArrayPushCell(ghPlayerSkins[id], SkinID);

    if ( SaveToVault )
        SavePlayerSkinsToVault(id);

    return 1;
}

stock PlayerHasSkin(id, SkinID) {

    new NumSkins = ArraySize(ghPlayerSkins[id]);

    for ( new i ; i < NumSkins ; i++ ) {
        if ( ArrayGetCell(ghPlayerSkins[id], i) == SkinID )
            return 1;
    }

    return 0;
}

stock SavePlayerSkinsToVault(id) {

    new szSteamID[32];
    get_user_authid(id, szSteamID, charsmax(szSteamID));

    new szTemp[512], len;
    new NumSkins = ArraySize(ghPlayerSkins[id]);

    for ( new i ; i < NumSkins ; i++ )
        len += formatex(szTemp[len], charsmax(szTemp) - len, "%d ", ArrayGetCell(ghPlayerSkins[id], i));

    //nvault_set(g_vault, szSteamID, szTemp);
    fvault_set_data(g_vault, szSteamID, szTemp);
}

stock IsSkinIDValid(SkinID) {

    new szKey[32];
    num_to_str(SkinID, szKey, charsmax(szKey));

    return TrieKeyExists(ghSkinInformation, szKey);
}

stock GetSkinInfo(SkinID, SkinInformation[enumSkin]) {

    new szKey[32];
    num_to_str(SkinID, szKey, charsmax(szKey));

    if ( ! TrieKeyExists(ghSkinInformation, szKey) )
        return 0;

    TrieGetArray(ghSkinInformation, szKey, SkinInformation, enumSkin);

    return 1;
}

public client_authorized(id) {

    new szData[512], szTemp[32], szSteamID[32];

    ghPlayerSkins[id] = ArrayCreate();

    get_user_authid(id, szSteamID, charsmax(szSteamID));
    //nvault_get(g_vault, szSteamID, szData, charsmax(szData));
    fvault_get_data(g_vault, szSteamID, szData, charsmax(szData));

    if ( ! szData[0] )
        return;

    do {
        strbreak(szData, szTemp, charsmax(szTemp), szData, charsmax(szData));
        ArrayPushCell(ghPlayerSkins[id], str_to_num(szTemp));
    } while ( szData[0] );

    LoadPoints(id);
    set_task( get_pcvar_float( g_TimeBetweenAds ), "ChatAdvertisements", _, _, _, "b" );
    set_task(1.0, "showSpecInfo", _, _, _, "b");
}

public GivePoints( id, level, cid ){
    if( !cmd_access( id, level, cid, 3) ) return PLUGIN_HANDLED;
    
    new arg[35];
    read_argv(1, arg, charsmax(arg));
    
    new target = cmd_target( id, arg, CMDTARGET_NO_BOTS );
    if( !target ) return PLUGIN_HANDLED;
    
    read_argv(2, arg, charsmax(arg));
    new points = str_to_num(arg);
    
    if( points <= 0 || points > MAX_POINTS ||  ghPlayerPoints[target] >= MAX_POINTS) return PLUGIN_HANDLED;

    ghPlayerPoints[target] += points;
    SavePoints( target );

    new name1[ 33 ], name2[ 33 ]
    get_user_name( id, name1, charsmax( name1 ) );
    get_user_name( target, name2, charsmax( name2 ) );

    client_print_color(0, print_chat, "%L",LANG_SERVER, "ADDED_POINTS_TO", g_szPrefix, name1, points, points > 1 ? "s" : "", name2 );
    
    return PLUGIN_HANDLED;
}

public RemovePoints( id, level, cid ){
    if( !cmd_access( id, level, cid, 3) ) return PLUGIN_HANDLED;
    
    new arg[35];
    read_argv(1, arg, charsmax(arg));
    
    new target = cmd_target( id, arg, CMDTARGET_NO_BOTS );
    if( !target ) return PLUGIN_HANDLED;
    
    read_argv(2, arg, charsmax(arg));
    new points = str_to_num(arg);
    
    if( points <= 0 || ghPlayerPoints[ target ] < points) return PLUGIN_HANDLED;

    ghPlayerPoints[ target ] -= points;

    if( ghPlayerPoints[ target ] < 0)
            ghPlayerPoints[ target ] = 0;

    SavePoints( target );

    new name1[ 33 ], name2[ 33 ]
    get_user_name( id, name1, charsmax( name1 ) );
    get_user_name( target, name2, charsmax( name2 ) );

    client_print_color(0, print_chat, "%L",LANG_SERVER, "REMOVED_POINTS_TO", g_szPrefix, name1, points, points > 1 ? "s" : "", name2 );
    
    return PLUGIN_HANDLED;
}

public PlayerSpawn( id ){
    if( !is_user_alive(id) )
        return PLUGIN_HANDLED;

    set_task( 1.0, "ShowInfo", id, _, _, "b");

    return PLUGIN_HANDLED;
}

public client_disconnect( id ){
    SavePoints( id );
    ArrayDestroy( ghPlayerSkins[id] );
}

public plugin_precache() {

    new szFilename[128];
    get_configsdir(szFilename, charsmax(szFilename));
    add(szFilename, charsmax(szFilename), "/");
    add(szFilename, charsmax(szFilename), INI_FILENAME);

    new hFile = fopen(szFilename, "rt");

    if (!hFile) {
		CreateNewIni(szFilename);
	}
        
    ghSkinInformation = TrieCreate();
    ghAllSkins = ArrayCreate();

    new szData[512], szKey[32], tempID;
    new tempSkinInformation[enumSkin];

    while (!feof(hFile)) {
        fgets(hFile, szData, charsmax(szData));
        trim(szData);

        if (szData[0] == ';' || ( szData[0] == '/' && szData[1] == '/' )) {
			continue;
		}
		
        new tempCost[64];
        parse(szData,
			tempSkinInformation[_WEAPONID], charsmax(tempSkinInformation[_WEAPONID]),
            tempSkinInformation[_FILENAME], charsmax(tempSkinInformation[_FILENAME]), 
            tempSkinInformation[_NAME], charsmax(tempSkinInformation[_NAME]), 
            tempCost, charsmax(tempCost));

        if (!file_exists(tempSkinInformation[_FILENAME])) {
            server_print("I can't find the file ^"%s^".", tempSkinInformation[_FILENAME]);
            continue;
        }

        RegisterHam(Ham_Item_Deploy, tempSkinInformation[_WEAPONID], "FwdItemDeployPost", 1)

        tempSkinInformation[_POINTS] = str_to_num(tempCost)

        tempID = GetSkinUniqueID(tempSkinInformation[_FILENAME]);
        ArrayPushCell(ghAllSkins, tempID)

        num_to_str(tempID, szKey, charsmax(szKey));
        TrieSetArray(ghSkinInformation, szKey, tempSkinInformation, enumSkin);

        precache_model(tempSkinInformation[_FILENAME]);
    }

    fclose(hFile);

    if ( ! ArraySize(ghAllSkins) )
        ExitPluginWithError("I can't find any valid skins in the ini file.");
}

public plugin_end() {

    ArrayDestroy(ghAllSkins);
    TrieDestroy(ghSkinInformation); 
}


public showSpecInfo(id)
{
    new players[ MAX_PLAYERS ], num;
    get_players(players, num, "ch");
    
    new id, target, szTargetName[32];
    
    set_dhudmessage(0, 0, 255, 0.70, 0.25, 0, 0.5, 1.0, 0.1, 0.1, -1);
    
    for(new i; i < num; i++)
    {
        id = players[i]

        if(!is_user_connected(id))
            continue;
        
        if(!is_user_alive(id))
        {
            target = pev(id, pev_iuser2);
            
            if(!target)
                continue;
            
            get_user_name(target, szTargetName, charsmax(szTargetName));
            
            show_dhudmessage(id, "%s ^n[ Skins: %d | Pontos: %i ]", szTargetName, ArraySize(target), ghPlayerPoints[target] );  
        }
    }

}

public ShowInfo(id)
{
    //set_dhudmessage(red = 0, green = 160, blue = 0, Float:x = -1.0, Float:y = 0.65, effects = 2, Float:fxtime = 6.0, Float:holdtime = 3.0, Float:fadeintime = 0.1, Float:fadeouttime = 1.5, bool:reliable = false)

    set_dhudmessage(0, 255, 0, 0.02, 0.25, 0, 0.5, 1.0, 0.1, 0.1, -1);
    show_dhudmessage(id, "[ PONTOS: %i ]", ghPlayerPoints[id]);

    return PLUGIN_CONTINUE;
}

public EventNewRound() {
    g_bRoundEnded = false;
}

public TerroristsWin( ) {
    if( g_bRoundEnded || get_playersnum() <= MIN_PLAYERS )
    {
        return  
    }

    new Players[ MAX_PLAYERS ], iNum, i
    
    get_players( Players, iNum, "ch" )
    
    //loop throw players
    for( --iNum; iNum >= 0; iNum-- )
    {
        i = Players[ iNum ]
        
        switch( cs_get_user_team( i ) )
        {
            case( CS_TEAM_T ):
            {
                addPoints(i, get_pcvar_num(Point_teamWin));
                client_print_color(i,print_chat, "%L", LANG_SERVER, "PLAYER_TEAM_WIN", g_szPrefix, "T", get_pcvar_num(Point_teamWin),get_pcvar_num(Point_teamWin)> 1 ? "s":"", ghPlayerPoints[i])
                ScreenFade(i, 1.0, 0, 200, 0, 50);
            }
            
            case( CS_TEAM_CT ):
            {

                removePoints(i, get_pcvar_num(Point_teamLost));
                client_print_color(i,print_chat, "%L", LANG_SERVER, "PLAYER_TEAM_LOST", g_szPrefix, "CT", get_pcvar_num(Point_teamLost),get_pcvar_num(Point_teamLost)> 1 ? "s":"", ghPlayerPoints[i])
                ScreenFade(i, 1.0, 0, 200, 0, 50);
                
            }
        }
    }
    
    g_bRoundEnded = true;
}

public CounterTerroristsWin( ) {
    if( g_bRoundEnded || get_playersnum() <= MIN_PLAYERS )
    {
        return  
    }

    new Players[ MAX_PLAYERS ], iNum, i
    
    get_players( Players, iNum, "ch" )
    
    //loop throw players
    for( --iNum; iNum >= 0; iNum-- )
    {
        i = Players[ iNum ]
        
        switch( cs_get_user_team( i ) )
        {
            case( CS_TEAM_T ):
            {
                removePoints(i, get_pcvar_num(Point_teamLost));
                client_print_color(i,print_chat, "%L", LANG_SERVER, "PLAYER_TEAM_LOST", g_szPrefix, "T", get_pcvar_num(Point_teamLost),get_pcvar_num(Point_teamLost)> 1 ? "s":"", ghPlayerPoints[i])
                ScreenFade(i, 1.0, 0, 200, 0, 50);
                
            }
            
            case( CS_TEAM_CT ):
            {
                addPoints(i, get_pcvar_num(Point_teamWin));
                client_print_color(i,print_chat, "%L", LANG_SERVER, "PLAYER_TEAM_WIN", g_szPrefix, "CT", get_pcvar_num(Point_teamWin),get_pcvar_num(Point_teamWin)> 1 ? "s":"", ghPlayerPoints[i])
                ScreenFade(i, 1.0, 0, 200, 0, 50);
                
            }
        }
    }
    
    g_bRoundEnded = true;
}
/*
    Death and kill system points
 */
public eDeathMsg()
{
    new iKiller = read_data(1);
    new iVictim = read_data(2);
    new isHeadshot = read_data(3);

    static killerName[32], victimName[32];
    
    get_user_name( iKiller, killerName, 31 );
    get_user_name( iVictim, victimName, 31 );
    
    static sWeapon[16]; read_data( 4, sWeapon, sizeof(sWeapon) - 1 );

    if( iKiller == iVictim && equal( sWeapon, "world", 5 ) ){
        //suicide
        removePoints(iVictim, get_pcvar_num(Point_Suicide));
        client_print_color(iVictim,print_chat, "%L", LANG_SERVER, "PLAYER_SUICIDE", g_szPrefix, get_pcvar_num(Point_Suicide),get_pcvar_num(Point_Suicide)> 1 ? "s":"", ghPlayerPoints[iVictim])
        ScreenFade(iVictim, 2.0, 200, 100, 0, 50);

    } else if( !iKiller && equal( sWeapon, "world", 5 ) ){
        //falled
        removePoints(iVictim, get_pcvar_num(Point_falled));
        client_print_color(iVictim,print_chat, "%L", LANG_SERVER, "PLAYER_FALLED", g_szPrefix, get_pcvar_num(Point_falled),get_pcvar_num(Point_falled)> 1 ? "s":"", ghPlayerPoints[iVictim])
        ScreenFade(iVictim, 2.0, 0, 100, 200, 50);

    } else if( equali( sWeapon, "knife", 5 ) ){
        //knife Kill
        removePoints(iVictim, get_pcvar_num(Point_dieKnife));
        client_print_color(iVictim,print_chat, "%L", LANG_SERVER, "PLAYER_DIED_KNIFE", g_szPrefix, killerName,get_pcvar_num(Point_dieKnife),get_pcvar_num(Point_dieKnife)> 1 ? "s":"", ghPlayerPoints[iVictim])
        ScreenFade(iVictim, 2.0, 200, 100, 0, 50);

        addPoints(iKiller, get_pcvar_num(Point_KillKnife));
        client_print_color(iKiller, print_chat, "%L", LANG_SERVER, "PLAYER_KILLED_KNIFE", g_szPrefix,victimName,get_pcvar_num(Point_KillKnife),get_pcvar_num(Point_KillKnife)> 1 ? "s":"", ghPlayerPoints[iKiller]);
               
    }else if( equali( sWeapon, "grenade", 7 ) ){
        //grenade kill
        removePoints(iVictim, get_pcvar_num(Point_dieHe));
        client_print_color(iVictim,print_chat, "%L", LANG_SERVER, "PLAYER_DIED_HE", g_szPrefix, killerName,get_pcvar_num(Point_dieHe),get_pcvar_num(Point_dieHe)> 1 ? "s":"", ghPlayerPoints[iVictim])
        ScreenFade(iVictim, 1.0, 255, 0, 0, 50);

        addPoints(iKiller, get_pcvar_num(Point_KillHe));
        client_print_color(iKiller, print_chat, "%L", LANG_SERVER, "PLAYER_KILLED_HE", g_szPrefix,victimName,get_pcvar_num(Point_KillHe),get_pcvar_num(Point_KillHe)> 1 ? "s":"", ghPlayerPoints[iKiller]);
    
    } if( isHeadshot && iKiller != iVictim ){
        //headshot
        removePoints( iVictim, get_pcvar_num(Point_dieHs) );
        client_print_color(iVictim, print_chat, "%L", LANG_SERVER, "PLAYER_DIED_HS", g_szPrefix, killerName,get_pcvar_num(Point_dieHs),get_pcvar_num(Point_dieHs)> 1 ? "s":"",ghPlayerPoints[iVictim]);
        
        addPoints( iKiller, get_pcvar_num(Point_Hs) );
        client_print_color( iKiller, print_chat, "%L", LANG_SERVER, "PLAYER_KILLED_HS", g_szPrefix,victimName,get_pcvar_num(Point_Hs),get_pcvar_num(Point_Hs)> 1 ? "s":"", ghPlayerPoints[iKiller]);
    }else if( iKiller != iVictim && !equal( sWeapon, "world", 5 )) {
        //normal kill
        removePoints(iVictim, get_pcvar_num(Point_dieKill));
        client_print_color(iVictim,print_chat, "%L", LANG_SERVER, "PLAYER_DIED", g_szPrefix, killerName,get_pcvar_num(Point_dieKill),get_pcvar_num(Point_dieKill)> 1 ? "s":"", ghPlayerPoints[iVictim])
        
        addPoints(iKiller, get_pcvar_num(Point_Kill));
        client_print_color(iKiller, print_chat, "%L", LANG_SERVER, "PLAYER_KILLED", g_szPrefix,victimName,get_pcvar_num(Point_Kill),get_pcvar_num(Point_Kill)> 1 ? "s":"", ghPlayerPoints[iKiller]);
    }

    SavePoints(iKiller);
    SavePoints(iVictim);
}

addPoints(id, points){
    if(points > MAX_POINTS)
        return;

    ghPlayerPoints[id] += points;
    return;
}

removePoints(id, points){

    if(ghPlayerPoints[id] >= points){
         ghPlayerPoints[id] -= points;
    }

    return;
}

public bomb_planted( planter )
{
    if(!is_user_connected(planter)) return PLUGIN_CONTINUE
    
    ghPlayerPoints[planter] += get_pcvar_num(Point_Plant);
    
    //ColorChat(planter,"^1[^4%s^1] ^1Plantaste a Bomba (^4+%i^1 ponto%s) <^4%i^1>.",g_szPrefix,get_pcvar_num(Point_Plant),get_pcvar_num(Point_Plant)> 1 ? "s":"", PlayerPoints[planter])
    return PLUGIN_CONTINUE
}

CreateNewIni(szFilename[]) {

    new hFile = fopen(szFilename, "wt");

    if ( ! hFile )
        ExitPluginWithError("I have failed to create the ini file.");

    fprintf(hFile, "; Default format of file...");
    fclose(hFile);

    ExitPluginWithError("My ini file is empty.");
}

public MainMenu(id)
{
    if( !is_user_alive( id ) )
    {
        client_print_color( id, print_chat,  "%L", LANG_SERVER, "REQUIRE_LIFE", g_szPrefix);
        return PLUGIN_HANDLED;
    }

    new szmainmenu[ 128 ]
    
    formatex(szmainmenu, charsmax(szmainmenu),"\r%s \y- \wEscolhe uma opção", MENU_TITLE);
    
    new mainmenu = menu_create(szmainmenu, "mainmenu_handler");

    menu_additem(mainmenu, "Comprar skins.", "1", 0)
    menu_additem(mainmenu, "Vender skins.", "2", 0)
    menu_additem(mainmenu, "Minhas skins.", "3", 0)
    menu_additem(mainmenu, "Doar pontos.", "4", 0)


    menu_setprop(mainmenu, MPROP_EXITNAME, "Sair.");
    menu_display(id, mainmenu, 0);
    return PLUGIN_HANDLED;
}

public mainmenu_handler(id, shop, item)
{
    if(item == MENU_EXIT || !is_user_connected( id ) || !is_user_alive( id ) )
    {
        menu_destroy(shop);
        return PLUGIN_HANDLED;
    }
    switch(item){
        case 0: SkinsMenu(id);
        case 1: SellSkinsMenu(id);
        case 2: PlayerSkinsMenu(id);
        case 3: DonatePointsMenu(id);
    }
    
    menu_destroy( shop );
    return PLUGIN_HANDLED;
}

/**
 * buy skins menu
 */
public SkinsMenu(id)
{

    new szShop[ 128 ]
    new szNameCostMenu[ 512 ]
    new szTempI[ 128 ]
    
    formatex(szShop, charsmax(szShop),"\r%s  \r- \wCompra aqui as tuas skins!", MENU_TITLE);
    
    new shop = menu_create(szShop, "SkinsMenu_handler");

    new tempSkinID, 
    NumSkins = ArraySize(ghAllSkins), 
    pSkins = ArraySize(ghPlayerSkins[id]), 
    tempSkinData[enumSkin];

    //client_print(0, print_chat, "numskins: %i pskins: %i", NumSkins,pSkins);
    if(NumSkins == pSkins)
    {
        client_print_color(id, print_chat, "%L",LANG_SERVER, "PLAYER_ALL_SKINS", g_szPrefix)
        menu_destroy(shop);
        return PLUGIN_HANDLED;
    }

    //Loop throght skins
    for ( new i ; i < NumSkins ; i++ ) {
        tempSkinID = ArrayGetCell(ghAllSkins, i);

        if( !IsSkinIDValid(tempSkinID) ) continue;
       
        //get info of skin
        GetSkinInfo(tempSkinID, tempSkinData)

        // if player dont have this skin lets print the option ;)
        if(!PlayerHasSkin(id, tempSkinID)){

            formatex(szNameCostMenu, charsmax(szNameCostMenu), "\w %s \R \yp o n  t o s.\r%i", tempSkinData[_NAME], tempSkinData[_POINTS])

            num_to_str(tempSkinID, szTempI, charsmax(szTempI))

            // finnaly add option
            menu_additem(shop, szNameCostMenu, szTempI, 0/*, menu_makecallback("CallbackMenu") */)
        }
    }

    menu_setprop(shop, MPROP_EXITNAME, "Sair.");
    menu_display(id, shop, 0);
    return PLUGIN_HANDLED;
}
/*public CallbackMenu(id, shop, item)
{
    new szData[6], szName[64];
    new item_access, item_callback;

    //Get information about the menu item
    menu_item_getinfo( shop, item, item_access, szData, charsmax( szData ), szName, charsmax( szName ), item_callback );

    // if player
    return (PlayerHasSkin(id, str_to_num(szData))) ? ITEM_DISABLED : ITEM_ENABLED
} */

public SkinsMenu_handler(id, shop, item)
{
    if(item == MENU_EXIT || !is_user_connected( id ) || !is_user_alive(id))
    {
        menu_destroy(shop);
        return PLUGIN_HANDLED;
    }
    
    new szData[6], szPlayerName[33];
    new item_access, item_callback;
    menu_item_getinfo( shop, item, item_access, szData,charsmax( szData ), _,_, item_callback );
    get_user_name(id, szPlayerName, charsmax(szPlayerName))

    // get Skin information
    new tmpSkindata[enumSkin]
    GetSkinInfo(str_to_num(szData), tmpSkindata)

    //verify if user have enugouh points!
    if(tmpSkindata[_POINTS] > ghPlayerPoints[id])
    {
        NoPoints( id ); 
        menu_destroy( shop ); 

        return PLUGIN_HANDLED;
    }
    //remove points of the buy
    ghPlayerPoints[id] -= tmpSkindata[_POINTS];
    SavePoints(id);

    //Add Skin to a player
    AddSkinToPlayer(id, str_to_num(szData), 1);

    //client_cmd(id, "drop %s", tmpSkindata[_WEAPONID]);
    client_cmd(id, "lastinv;lastinv;");

    // Screen fading
    ScreenFade(id, 1.0, 0, 200, 0, 70);
    client_cmd(id, "spk ^"vox/deeoo buzwarn woop weapon unlocked^"");

    client_print_color(id, print_chat, "%L",LANG_SERVER, "PLAYER_BUY_SKIN", g_szPrefix, tmpSkindata[_NAME], tmpSkindata[_POINTS])

    client_print_color(0, print_chat,  "%L", LANG_SERVER, "BUY_SKIN_ALL", g_szPrefix, szPlayerName,tmpSkindata[_NAME], tmpSkindata[_POINTS])

    menu_destroy(shop);
    return PLUGIN_HANDLED;
}

public PlayerSkinsMenu(id)
{

    new szPlayerSkinsmenu[ 128 ]
    new szNameCostMenu[ 512 ]
    new szTempI[ 128 ]
    
    formatex(szPlayerSkinsmenu, charsmax(szPlayerSkinsmenu),"\r%s  \r- \wEscolhe a skin padrão!", MENU_TITLE);
    
    new playerSkinsmenu = menu_create(szPlayerSkinsmenu, "playerSkinMenu_handler");

    new tempSkinID, NumSkins = ArraySize(ghPlayerSkins[id]);

    if(!NumSkins){
        client_print_color(id,print_chat, "%L", LANG_SERVER, "PLAYER_NO_SKINS", g_szPrefix)
        show_menu( id, 0, "^n", 1 );
        //menu_cancel(playerSkinsmenu);
        menu_destroy(playerSkinsmenu);
        return PLUGIN_HANDLED
    }


    //Loop throght player skins
    for ( new i ; i < NumSkins ; i++ ) {
        tempSkinID = ArrayGetCell(ghPlayerSkins[id], i);

        if( !IsSkinIDValid(tempSkinID) ) continue;

        //client_print(id, print_chat, "temp skin id: %i", tempSkinID);
        
        new tempSkinData[enumSkin]
        GetSkinInfo(tempSkinID, tempSkinData)

        //skins compradas
        formatex(szNameCostMenu, charsmax(szNameCostMenu), "\y %s \w(Comprada por \r%i\wpts.)", tempSkinData[_NAME], tempSkinData[_POINTS])

        num_to_str(tempSkinID, szTempI, charsmax(szTempI))

        // finnaly add option
        menu_additem(playerSkinsmenu, szNameCostMenu, szTempI, 0);
        
    }

    menu_display(id, playerSkinsmenu, 0);
    return PLUGIN_HANDLED
}

public playerSkinMenu_handler(id, shop, item)
{
    if(item == MENU_EXIT || !is_user_connected( id ) || !is_user_alive( id ) )
    {
        menu_destroy(shop);
        return PLUGIN_HANDLED;
    }

    new szData[6], szName[64];
    new item_access, item_callback;
    new tempSkin[enumSkin]
    menu_item_getinfo( shop, item, item_access, szData,charsmax( szData ), szName,charsmax( szName ), item_callback );

    if( PlayerHasSkin(id, str_to_num(szData)) )
    {
        for(new i; i < ArraySize(ghPlayerSkins[id]); i++){
            if(ArrayGetCell(ghPlayerSkins[id], i) == str_to_num(szData)){
                ArrayDeleteItem(ghPlayerSkins[id], i)
            }
        }
        GetSkinInfo(str_to_num(szData), tempSkin)
        AddSkinToPlayer(id, str_to_num(szData), 1)

        // change the current skin in hand to update skin
        client_cmd(id, "lastinv;lastinv")
        client_print_color(id,print_chat, "%L", LANG_SERVER, "SKIN_CHANGED", g_szPrefix, tempSkin[_NAME])

        // Screen fading
        ScreenFade(id, 1.0, 0, 0, 200, 70);
        client_cmd(id, "spk ^"vox/weapon switch^"");
    }

    menu_destroy( shop );
    return PLUGIN_HANDLED;
}

public SellSkinsMenu(id)
{
    new szSellMenu[ 128 ]
    new szNameCostMenu[ 512 ]
    new szTempI[ 128 ]
    
    formatex(szSellMenu, charsmax(szSellMenu),"\r%s  \r- \wVende aqui as tuas skins!", MENU_TITLE);
    
    new sellMenu = menu_create(szSellMenu, "sellSkinMenuConfirm_handler");

    new tempSkinID, NumSkins = ArraySize(ghPlayerSkins[id]);

    if(!NumSkins){
        client_print_color(id,print_chat, "%L", LANG_SERVER, "PLAYER_NO_SKINS", g_szPrefix)
        show_menu( id, 0, "^n", 1 );
        //menu_cancel(sellMenu);
        menu_destroy(sellMenu);
        return PLUGIN_HANDLED;
    }

    //Loop throght player skins
    for ( new i ; i < NumSkins ; i++ ) {
        tempSkinID = ArrayGetCell(ghPlayerSkins[id], i);

        if( !IsSkinIDValid(tempSkinID) ) continue;
        
        new tempSkinData[enumSkin]
        GetSkinInfo(tempSkinID, tempSkinData);

        //skins compradas
        formatex(szNameCostMenu, charsmax(szNameCostMenu), "\y %s \w(Comprada por \r%i\wpts.)", tempSkinData[_NAME], tempSkinData[_POINTS])

        num_to_str(tempSkinID, szTempI, charsmax(szTempI))

        // finnaly add option
        menu_additem(sellMenu, szNameCostMenu, szTempI, 0);
        
    }

    menu_display(id, sellMenu, 0);
    return PLUGIN_HANDLED
}

public sellSkinMenuConfirm_handler(id, menu, item)
{
    if(item == MENU_EXIT || !is_user_connected( id ) || !is_user_alive(id))
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    new szData[6];
    new item_access, item_callback;
    menu_item_getinfo( menu, item, item_access, szData,charsmax( szData ), _,_, item_callback );

    //open confirmation menu
    ConfirmSellSkinsMenu(id, str_to_num(szData))

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public ConfirmSellSkinsMenu(id, _skinID)
{

    new NumSkins = ArraySize(ghPlayerSkins[id]);

    if(!NumSkins || !_skinID){
        show_menu( id, 0, "^n", 1 );
        return PLUGIN_HANDLED
    }  

    new szConfirmMenu[ 256 ]
    new tmpSkinInfo[enumSkin]
    GetSkinInfo(_skinID, tmpSkinInfo)

    formatex(szConfirmMenu, charsmax(szConfirmMenu),"\r%s  \r- \wConfirma a tua venda", MENU_TITLE);
    formatex(szConfirmMenu, charsmax(szConfirmMenu),"%s ^n^n \wConfirma para venderes \r%s\w.", szConfirmMenu, tmpSkinInfo[_NAME]); 
    formatex(szConfirmMenu, charsmax(szConfirmMenu), "%s ^n \wSo receberás \r %i \ypontos \r(%i %%)", szConfirmMenu, floatround((float(tmpSkinInfo[_POINTS]) / 100) * PERCENT_SALE ), PERCENT_SALE)


    new ConfirmMenu = menu_create(szConfirmMenu, "sellSkinMenu_handler");

    new szSkinId[33]; num_to_str(_skinID, szSkinId, charsmax(szSkinId));

    menu_additem(ConfirmMenu, "Sim", szSkinId, 0);
    menu_additem(ConfirmMenu, "Não", "0", 0);

    menu_display(id, ConfirmMenu, 0);
    return PLUGIN_HANDLED
}

public sellSkinMenu_handler(id, shop, item)
{
    if(item == MENU_EXIT || !is_user_connected( id ) || !is_user_alive(id))
    {
        menu_destroy(shop);
        return PLUGIN_HANDLED;
    }

    new szData[6];
    new item_access, item_callback;
    new tempSkin[enumSkin], szPlayerName[33];
    get_user_name(id, szPlayerName, charsmax(szPlayerName))
    menu_item_getinfo( shop, item, item_access, szData,charsmax( szData ), _,_, item_callback );

    if( PlayerHasSkin(id, str_to_num(szData)) )
    {
        for(new i; i < ArraySize(ghPlayerSkins[id]); i++){
            if(ArrayGetCell(ghPlayerSkins[id], i) == str_to_num(szData)){
                ArrayDeleteItem(ghPlayerSkins[id], i)
            }
        }
        GetSkinInfo(str_to_num(szData), tempSkin)

        //calcule percentage
        new sellPrice = floatround( (float(tempSkin[_POINTS]) / 100) * PERCENT_SALE )
        ghPlayerPoints[id] += sellPrice
        SavePlayerSkinsToVault(id)
        SavePoints(id)

        client_print_color(id, print_chat, "%L",LANG_SERVER, "PLAYER_SELL_SKIN", g_szPrefix, tempSkin[_NAME], sellPrice);
        client_print_color(0, print_chat, "%L",LANG_SERVER, "SELL_SKIN", g_szPrefix,szPlayerName, tempSkin[_NAME], sellPrice);
        client_cmd(id, "lastinv;lastinv");

        // Screen fading
        ScreenFade(id, 1.0, 200, 0, 0, 70);
        client_cmd(id, "spk ^"vox/woop buzwarn deeoo weapon locked^"");
    }
    menu_destroy( shop );
    return PLUGIN_HANDLED;
}

public DonatePointsMenu(id)
{
    new menuTitle[128]
    formatex(menuTitle, charsmax(menuTitle),"\r%s  \r- \wEscolhe um jogador para doar pontos!", MENU_TITLE);
    
    //Create a variable to hold the menu
    new menu = menu_create( menuTitle, "donatepoints_handler" );

    //We will need to create some variables so we can loop through all the players
    new players[32], pnum, tempid;

    //Some variables to hold information about the players
    new szName[32], szUserId[32];

    //Fill players with available players
    get_players( players, pnum, "chi" ); // flag "a" because we are going to add health to players, but this is just for this specific case

    if(pnum <= 1 ){
        client_print_color(id,print_chat, "%L", LANG_SERVER, "PLAYER_NO_PLAYERS", g_szPrefix)
        return PLUGIN_HANDLED
    }

    //Start looping through all players
    for ( new i; i<pnum; i++ )
    {
        //Save a tempid so we do not re-index
        tempid = players[i];

        // remove the self player
        //if(tempid == id) continue;

        //Get the players name and userid as strings
        get_user_name( tempid, szName, charsmax( szName ) );
        //We will use the data parameter to send the userid, so we can identify which player was selected in the handler
        formatex( szUserId, charsmax( szUserId ), "%d", get_user_userid( tempid ) );

        //Add the item for this player
        menu_additem( menu, szName, szUserId, 0 );
    }

    //We now have all players in the menu, lets display the menu
    menu_display( id, menu, 0 );
    
    return PLUGIN_HANDLED;
}

public donatepoints_handler(id, menu, item){
     //Do a check to see if they exited because menu_item_getinfo ( see below ) will give an error if the item is MENU_EXIT
    if ( item == MENU_EXIT )
    {
        menu_destroy( menu );
        return PLUGIN_HANDLED;
    }


    new szData[6], _access, item_callback;

    menu_item_getinfo( menu, item, _access, szData,charsmax( szData ), _,_, item_callback );

    //Get the userid of the player that was selected
    new userid = str_to_num( szData );

    //Try to retrieve player index from its userid
    new player = find_player( "k", userid ); // flag "k" : find player from userid

    //If player == 0, this means that the player's userid cannot be found
    //If the player is still alive ( we had retrieved alive players when formating the menu but some players may have died before id could select an item from the menu )
    if ( player ){
        ghPlayerToReciveDonate = player;
        client_cmd(id, "messagemode ^"Quantidade_de_pontos^"");
    } 

    menu_destroy( menu );
    return PLUGIN_HANDLED;
}

public DonatePoints(id)
{
    new arg[35];
    read_argv(1, arg, charsmax(arg));
    new donatePoints = str_to_num(arg);

    if(!donatePoints || !ghPlayerToReciveDonate) return PLUGIN_HANDLED

    if(!is_user_connected(ghPlayerToReciveDonate)) {
        client_print_color(id,print_chat, "%L", LANG_SERVER, "PLAYER_NOTFOUND_PLAYER", g_szPrefix)

        return PLUGIN_HANDLED
    }

    if(id == ghPlayerToReciveDonate)
    {
        client_print_color(id,print_chat, "%L", LANG_SERVER, "PLAYER_GIVE_HIMSELF", g_szPrefix)
        return PLUGIN_HANDLED
    }

    if(ghPlayerPoints[id] < donatePoints)
    {
        client_print_color(id,print_chat, "%L", LANG_SERVER, "PLAYER_GIVEPOINTS_INVALID", g_szPrefix)
        return PLUGIN_HANDLED
    }

    if(MIN_DONATION > donatePoints)
    {
        client_print_color(id,print_chat, "%L", LANG_SERVER, "PLAYER_MIN_DONATION", g_szPrefix, MIN_DONATION)
        return PLUGIN_HANDLED
    }

    // REMOVE donated points
    ghPlayerPoints[id] -= donatePoints

    new szNameID[33], szNameReciveDonate[33];
    get_user_name(id, szNameID, charsmax(szNameID));
    get_user_name(ghPlayerToReciveDonate, szNameReciveDonate, charsmax(szNameReciveDonate));

    client_print_color(id,print_chat, "%L", LANG_SERVER, "PLAYER_DONATION", g_szPrefix, donatePoints, szNameReciveDonate)

    client_print_color(ghPlayerToReciveDonate, print_chat, "%L",LANG_SERVER, "PLAYER_DONATION", g_szPrefix, donatePoints, szNameID);

    // add donated points
    ghPlayerPoints[ghPlayerToReciveDonate] += donatePoints;

    SavePoints(id);
    SavePoints(ghPlayerToReciveDonate);

    // reset variable for security reasons ?
    ghPlayerToReciveDonate = 0;

    return PLUGIN_HANDLED
}

/**
 * Sets the model
 * @param {entity} entity get id of player by entity and weapon id
 */
public FwdItemDeployPost( entity ) {
    const m_pPlayer = 41;
    const m_iId = 43;

    new id = get_pdata_cbase( entity, m_pPlayer, 4 );
    
    if( is_user_alive( id ) ) {
        new weaponId = get_pdata_int( entity, m_iId, 4 );

        new tempSkinID, NumSkins = ArraySize(ghPlayerSkins[id]), tempData[enumSkin];

        for ( new i ; i < NumSkins ; i++ ) {
            tempSkinID = ArrayGetCell(ghPlayerSkins[id], i);
            GetSkinInfo(tempSkinID, tempData)

            if( 0 < weaponId <= CSW_P90 && PlayerHasSkin( id, tempSkinID ) && get_weaponid( tempData[_WEAPONID] ) == weaponId ) {
                set_pev(id, pev_viewmodel2, tempData[_FILENAME]);
                //break;
            } 
        }
    }
}  

LoadPoints( id ) {
    if( !is_user_bot( id ) && !is_user_hltv( id ) )
    {
        new vaultkey[ 64 ], vaultdata[ 256 ], points[ 33 ], szSteamId[ 64 ];
        get_user_authid( id, szSteamId, charsmax( szSteamId ) );
        
        format( vaultkey, charsmax( vaultkey ), "%sPONTOS", szSteamId );
        
        if(!fvault_get_data( g_vault, vaultkey, vaultdata, 255 ))
        {
            ghPlayerPoints[ id ] = 0
            return PLUGIN_HANDLED
        }
        
        parse( vaultdata, points, 32 );

        if (str_to_num( points ) > MAX_POINTS){
            ghPlayerPoints[ id ] = 0;
            SavePoints( id );
            return PLUGIN_HANDLED;
        }

        ghPlayerPoints[ id ] = str_to_num( points );
    }

    return PLUGIN_HANDLED
}

SavePoints( id ) {
    if( !is_user_bot( id ) && !is_user_hltv( id ) )
    {
        new vaultkey[ 64 ], vaultdata[ 256 ], szSteamId[ 64 ];
        get_user_authid( id, szSteamId, charsmax( szSteamId ) )
        
        formatex( vaultkey, charsmax( vaultkey ), "%sPONTOS", szSteamId )
        formatex( vaultdata, charsmax( vaultdata ), "%i", ghPlayerPoints[ id ] )
        
        //nvault_set( g_vault, vaultkey, vaultdata )
        fvault_set_data( g_vault, vaultkey, vaultdata )
    }

    return PLUGIN_HANDLED
}

NoPoints( id ) {
    client_print_color(id,print_chat, "%L", LANG_SERVER, "PLAYER_NOENOUGH_POINTS", g_szPrefix)
}


GetSkinUniqueID( szSkinFilename[] ) {

    static NextUniqueID;
    new szTemp[32];

    if ( ! NextUniqueID ) {
        
        //NextUniqueID = fvault_get_vaultnum(g_vault, "COUNTER");

        fvault_get_data(g_vault, "COUNTER", szTemp, charsmax(szTemp));
        NextUniqueID = str_to_num(szTemp);

        if ( ! NextUniqueID ) {
            //nvault_set(g_vault, "COUNTER", "1");
            fvault_set_data(g_vault, "COUNTER", "1");
            NextUniqueID = 1;
        }
    }

    //new Result = fvault_get_keynum(g_vault, szSkinFilename);

    fvault_get_data(g_vault, szSkinFilename, szTemp, charsmax(szTemp));

    new Result = str_to_num(szTemp);

    if ( ! Result ) {
        num_to_str(NextUniqueID, szTemp, charsmax(szTemp));
        fvault_set_data(g_vault, szSkinFilename, szTemp);

        NextUniqueID++;
        num_to_str(NextUniqueID, szTemp, charsmax(szTemp));
        fvault_set_data(g_vault, "COUNTER", szTemp);

        return NextUniqueID - 1;
    }
    
    return Result;
}

stock ScreenFade(plr, Float:fDuration, red, green, blue, alpha)
{
    new i = plr ? plr : get_maxplayers();
    if( !i )
    {
        return 0;
    }
    
    message_begin(plr ? MSG_ONE : MSG_ALL, get_user_msgid( "ScreenFade"), {0, 0, 0}, plr);
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(4096);
    write_byte(red);
    write_byte(green);
    write_byte(blue);
    write_byte(alpha);
    message_end();
    
    return 1;
}  

ExitPluginWithError(fmt[], ...) {

    new buffer[128];
    vformat(buffer, charsmax(buffer), fmt, 1);

    set_fail_state(buffer);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2070\\ f0\\ fs16 \n\\ par }
*/
