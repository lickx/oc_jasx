//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  OpenCollar six app for switching outfits using the JasX outfit system   //
//  160827.1                                                                //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2016 - Lotek Ixtar                                        //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//                      https://github.com/lickx/oc_jasx                    //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

string g_sAppVersion = "¹⋅⁴";

string g_sParentMenu = "Apps";
string g_sSubMenu = "JasX";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER            = 500;
integer CMD_TRUSTED          = 501;
//integer CMD_GROUP          = 502;
integer CMD_WEARER           = 503;
integer CMD_EVERYONE         = 504;
//integer CMD_RLV_RELAY      = 507;
//integer CMD_SAFEWORD       = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
//integer SAY = 1004;
integer REBOOT              = -1000;
integer LINK_DIALOG         = 3;
//integer LINK_RLV            = 4;
integer LINK_SAVE           = 5;
integer LINK_UPDATE = -10;
//integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
//integer LM_SETTING_RESPONSE = 2002;
//integer LM_SETTING_DELETE = 2003;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer g_iAuth;

key g_kWearer;
string g_sSettingToken = "jasx_";
//string g_sGlobalToken = "global_";

list g_lMenuIDs;  //three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;

//string DRESS = "Dress up";
//string UNDRESS = "Dress down";
//string NUDE = "Get nude";
string BACKMENU = "⏎";
string UPMENU = "BACK";

key     g_kMenuClicker;

//outfit vars
integer g_iListener;
integer g_iFolderRLV = 98745023;
integer g_iFolderRLVSearch = 98745025;
integer g_iTimeOut = 30; //timeout on viewer response commands
//integer g_iRlvOn = FALSE;
//integer g_iRlvaOn = FALSE;
string g_sCurrentPath;
string g_sPathPrefix = "JasX"; //we look for outfits in here

/*integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}*/

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string iMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    //Debug("Made menu.");
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, iMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, iMenuType];
}

JasxMainMenu(key keyID, integer iAuth) {
    string sPrompt = "\nJasX dress/undress";
    sPrompt += "\n\nWhat would you like to do?";
    list lMyButtons = [];
    if (iAuth >= CMD_OWNER && iAuth <= CMD_TRUSTED) lMyButtons = ["Get Nude", "Undress"];
    lMyButtons += ["Dress", "Outfits"];
    list lStaticButtons = [UPMENU];
    Dialog(keyID, sPrompt, lMyButtons, lStaticButtons, 0, iAuth, "jasxmain");
}

JasxActionMenu(key keyID, integer iAuth, string sAction, string sDialog) {
    string sPrompt = "\nJasX dress/undress";
    sPrompt += "\n\nWhat should be "+sAction+"?";
    list lMyButtons = ["Head", "Arms", "Torso", "Groin", "Boots", "Everything"];
    list lStaticButtons = [BACKMENU];
    Dialog(keyID, sPrompt, lMyButtons, lStaticButtons, 0, iAuth, sDialog);
}

JasxOutfitsMenu(key kID, integer iAuth) {
    g_kMenuClicker = kID; //on our listen response, we need to know who to pop a dialog for
    g_iAuth = iAuth;
    g_sCurrentPath = g_sPathPrefix + "/";
    llSetTimerEvent(g_iTimeOut);
    g_iListener = llListen(g_iFolderRLV, "", g_kWearer, "");
    llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
}

FolderMenu(key keyID, integer iAuth,string sFolders) {
    string sPrompt = "\n[http://www.opencollar.at/outfits.html JasX Outfits]";
    sPrompt += "\n\nCurrent Path = "+g_sCurrentPath;
    list lMyButtons;
    // and dispay the menu
    list lStaticButtons;
    if (g_sCurrentPath == g_sPathPrefix+"/") { //If we're at root, don't bother with BACKMENU
        lMyButtons = llParseString2List(sFolders,[","],[""]);
        integer idx = llListFindList(lMyButtons, ["OnAttach"]);
        if (~idx) lMyButtons = llDeleteSubList(lMyButtons, idx, idx);
        lMyButtons = llListSort(lMyButtons, 1, TRUE);
        lStaticButtons = [UPMENU];
    } else {
        lStaticButtons = ["WEAR",UPMENU,BACKMENU];
    }
    Dialog(keyID, sPrompt, lMyButtons, lStaticButtons, 0, iAuth, "folder");
}

WearFolder (string sStr) {
    string sOutfit = llGetSubString(sStr, llStringLength(g_sPathPrefix)+1, -2);
    llRegionSayTo(llGetOwner(), 1, "jasx.setoutfit "+sOutfit);
}

ConfirmDeleteMenu(key kAv, integer iAuth) {
    string sPrompt ="\nDo you really want to uninstall the "+g_sSubMenu+" App?";
    Dialog(kAv, sPrompt, ["Yes","No","Cancel"], [], 0, iAuth,"rmtitler");
}

UserCommand(integer iAuth, string sStr, key kAv, integer bFromMenu) {
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sAction = llToLower(llList2String(lParams, 1));
    string sLowerStr = llToLower(sStr);
    if (sLowerStr == "menu jasx" || sLowerStr == "jasx") {
//        string ON_OFF ;
        string sPrompt;
        sPrompt = "\n[http://www.opencollar.at/titler.html Titler]\t"+g_sAppVersion+"\n\n";
//        if(g_iOn == TRUE) ON_OFF = "ON" ;
//        else ON_OFF = "OFF" ;
        JasxMainMenu(kAv, iAuth);
        return;
    } else if (sLowerStr == "joutfits" || sLowerStr == "menu joutfits") {
        JasxOutfitsMenu(kAv, iAuth);
        return;
    } else if ( (sLowerStr == "nude" || sLowerStr == "menu nude") &&
                (iAuth >= CMD_OWNER && iAuth <= CMD_TRUSTED)) {
        JasxActionMenu(kAv, iAuth, "nude", "jasxnude");
    } else if ( (sLowerStr == "undress" || sLowerStr == "menu undress") &&
                (iAuth >= CMD_OWNER && iAuth <= CMD_TRUSTED)) {
        JasxActionMenu(kAv, iAuth, "unworn", "jasxundress");
    } else if (sLowerStr == "dress" || sLowerStr == "menu dress") {
        JasxActionMenu(kAv, iAuth, "worn", "jasxdress");
    } else if (llSubStringIndex(sStr,"jwear ") == 0) {
        sLowerStr = llDeleteSubString(sStr,0,llStringLength("jwear ")-1);
        if (sLowerStr) { //we have a folder to try find...
            llSetTimerEvent(g_iTimeOut);
            g_iListener = llListen(g_iFolderRLVSearch, "", g_kWearer, "");
            g_kMenuClicker = kAv;
//          if (g_iRlvaOn) {
//              llOwnerSay("@findfolders:"+sLowerStr+"="+(string)g_iFolderRLVSearch);
//          }
//          else {
                llOwnerSay("@findfolder:"+sLowerStr+"="+(string)g_iFolderRLVSearch);
//          }
        }
        if (bFromMenu) JasxOutfitsMenu(kAv, iAuth);
        return;
    } else if (sStr == "rm jasx") {
            if (kAv!=g_kWearer && iAuth!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kAv);
            else ConfirmDeleteMenu(kAv, iAuth);
    }
}

default{
    state_entry(){
       // llSetMemoryLimit(36864);
        g_kWearer = llGetOwner();
        //Debug("State Entry Event ended");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID){
        //Debug("Link Message Event");
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);        
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMenuType == "jasxmain") { 
                    if (sMessage == UPMENU) llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == "Get Nude") JasxActionMenu(kAv, iAuth, "nude", "jasxnude");
                    else if (sMessage == "Undress") JasxActionMenu(kAv, iAuth, "unworn", "jasxundress");
                    else if (sMessage == "Dress") JasxActionMenu(kAv, iAuth, "worn", "jasxdress");
                    else if (sMessage == "Outfits") JasxOutfitsMenu(kAv, iAuth);
                    else {
                        if (sMessage == "OFF") UserCommand(iAuth, "jasx on", kAv, FALSE); // ??
                        else if (sMessage == "ON") UserCommand(iAuth, "jasx off", kAv, FALSE);
                        UserCommand(iAuth, "menu jasx", kAv, FALSE);
                    }
                } else if (sMenuType == "folder" || sMenuType == "multimatch") {
                    g_kMenuClicker = kAv;
                    if (sMessage == UPMENU)
                        llMessageLinked(LINK_THIS, iAuth, "menu jasx", kAv);
                    else if (sMessage == BACKMENU) {
                        list lTempSplit = llParseString2List(g_sCurrentPath,["/"],[]);
                        lTempSplit = llList2List(lTempSplit,0,llGetListLength(lTempSplit) -2);
                        g_sCurrentPath = llDumpList2String(lTempSplit,"/") + "/";
                        llSetTimerEvent(g_iTimeOut);
                        g_iAuth = iAuth;
                        g_iListener = llListen(g_iFolderRLV, "", g_kWearer, "");
                        llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
                    } else if (sMessage == "WEAR") {
                        WearFolder(g_sCurrentPath);
                        JasxOutfitsMenu(kAv, iAuth);
                    }
                    else if (sMessage != "") {
                        g_sCurrentPath += sMessage + "/";
                        if (sMenuType == "multimatch") g_sCurrentPath = sMessage + "/";
                        llSetTimerEvent(g_iTimeOut);
                        g_iAuth = iAuth;
                        g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
                        llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
                    }
                } else if (sMenuType == "jasxnude") {
                    if (sMessage == UPMENU) {
                        llMessageLinked(LINK_THIS, iAuth, "menu jasx", kAv);
                        return;
                    } else if (sMessage == "Everything") llWhisper(1, "jasx.setclothes bits");
                    else llWhisper(1, "jasx.setclothes Bits/"+sMessage);
                    JasxMainMenu(kAv, iAuth);
                } else if (sMenuType == "jasxundress") {
                    if (sMessage == UPMENU) {
                        llMessageLinked(LINK_THIS, iAuth, "menu jasx", kAv);
                        return;
                    } else if (sMessage == "Everything") llWhisper(1, "jasx.setclothes underwear");
                    else llWhisper(1, "jasx.setclothes Underwear/"+sMessage);
                    JasxMainMenu(kAv, iAuth);
                } else if (sMenuType == "jasxdress") {
                    if (sMessage == UPMENU) {
                        llMessageLinked(LINK_THIS, iAuth, "menu jasx", kAv);
                        return;
                    } else if (sMessage == "Everything") llWhisper(1, "jasx.setclothes dressed");
                    else llWhisper(1, "jasx.setclothes Dressed/"+sMessage);
                    JasxMainMenu(kAv, iAuth);
                } else if (sMenuType == "rmjasx") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                    if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    listen(integer iChan, string sName, key kID, string sMsg) {
        //llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        //Debug((string)iChan+"|"+sName+"|"+(string)kID+"|"+sMsg);
        if (iChan == g_iFolderRLV) { //We got some folders to process
            FolderMenu(g_kMenuClicker,g_iAuth,sMsg); //we use g_kMenuClicker to respond to the person who asked for the menu
            g_iAuth = CMD_EVERYONE;
        }
        else if (iChan == g_iFolderRLVSearch) {
            if (sMsg == "") {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"That outfit couldn't be found in #RLV/"+g_sPathPrefix,kID);
            } else { // we got a match
                if (llSubStringIndex(sMsg,",") < 0) {
                    g_sCurrentPath = sMsg;
                    WearFolder(g_sCurrentPath);
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Loading outfit #RLV/"+sMsg,kID);
                } else {
                    string sPrompt = "\nPick one!";
                    list lFolderMatches = llParseString2List(sMsg,[","],[]);
                    Dialog(g_kMenuClicker, sPrompt, lFolderMatches, [UPMENU], 0, g_iAuth, "multimatch");
                    g_iAuth = CMD_EVERYONE;
                }
            }
        }
    }

    timer() {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
    }

    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) llResetScript();
    }

    on_rez(integer param){
        llResetScript();
    }
}
