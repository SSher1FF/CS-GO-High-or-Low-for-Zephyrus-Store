#include <sourcemod>
#include <sdktools>
#include <store>
#include <multicolors>

#define PREFIX " \x04[High Or Low]\x01"
#define MENUPREFIX "[High Or Low]"



int g_iRand1, g_iRand2;
int g_iManualAmount[MAXPLAYERS + 1] = 100;

bool g_bTypingAmount[MAXPLAYERS + 1] = false;

ConVar g_cvMinAmount;
ConVar g_cvMaxAmount;

public Plugin myinfo = 
{
	name = "High or Low - Zephyrus Store",
	author = "SheriF",
	description = "Higher & Lower Gamble",
	version = "1.00",
	url = ""
};

public void OnPluginStart()
{
	g_cvMinAmount = CreateConVar("sm_hol_min_amount", "50", "The minimum amount of Credits to play High or Low");
	g_cvMaxAmount = CreateConVar("sm_hol_max_amount", "500", "The maximum amount of Credits to play High or Low");
	RegConsoleCmd("sm_hol", highorlow);
	
	AutoExecConfig(true, "highorlow");
}

public void OnClientPostAdminCheck(int client)
{
	g_iManualAmount[client] = 100;
	g_bTypingAmount[client] = false;
}

public Action highorlow(int client, int args)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		ShowMainMenu(client);
	}
	return Plugin_Handled;
}

public int menuHandler_HolMenu(Menu menu, MenuAction action, int client, int itemNUM)
{
	if (action == MenuAction_Select)
	{
		switch (itemNUM)
		{
			case 0:
			{
				g_bTypingAmount[client] = true;
				PrintToChat(client, "Please type an amount of credits in chat");
			}
			case 1:
			{
				if (Store_GetClientCredits(client) < g_iManualAmount[client])
					CPrintToChat(client, "%s You dont have enough credits to play High or Low",PREFIX);

				else
				{
					g_iRand1 = GetRandomInt(2, 99);
					g_iRand2 = GetRandomInt(1, 100);
					while(g_iRand1==g_iRand2)
		 				g_iRand2 = GetRandomInt(1, 100);
		 			
					Menu HolMenu1 = new Menu(menuHandler_HolMenu1);
					HolMenu1.SetTitle("%s A number between 1 to 100 has been chosen for you\n guess if the next number will be higher or lower than the chosen number", MENUPREFIX);
					
					HolMenu1.AddItem("","HIGHER");
					HolMenu1.AddItem("","LOWER");
					
					HolMenu1.ExitButton = false;
					HolMenu1.Display(client, MENU_TIME_FOREVER);
			
					Store_SetClientCredits(client, Store_GetClientCredits(client) - g_iManualAmount[client]);
					PrintCenterText(client,"The chosen number is: \x10%d", g_iRand1);
					CPrintToChat(client,"%s The chosen number is: \x10%d", PREFIX,g_iRand1);
				}
			}
		}
	}
}

public int menuHandler_HolMenu1 (Menu menu, MenuAction action, int client, int ItemNum)
{
	if (action == MenuAction_Select)
	{
		switch (ItemNum)
		{
			case 0:
			{
				if(g_iRand2>g_iRand1)
				{
					int win = (g_iManualAmount[client]/(100-g_iRand1));
					int credits = g_iManualAmount[client] * win;
					if(credits==g_iManualAmount[client])
					{
						credits = 2*g_iManualAmount[client];
						CPrintToChat(client, "%s You won \x04%d\x01 Credits", PREFIX,(credits/2));
					}
					else if(credits != g_iManualAmount[client])
						CPrintToChat(client, "%s You won \x04%d\x01 Credits", PREFIX,credits);
	
					Store_SetClientCredits(client, Store_GetClientCredits(client) + credits);
				}
				else
					CPrintToChat(client, "%s You \x07lost\x01 your bet",PREFIX);

				PrintCenterText(client,"The next number was: \x10%d", g_iRand2);
				CPrintToChat(client,"%s The next number was: \x10%d", PREFIX,g_iRand2);
			}
			case 1:
			{
				if(g_iRand2<g_iRand1)
				{
					int win = (g_iManualAmount[client]/(g_iRand1));
					int credits = g_iManualAmount[client] * win;
					if(credits==g_iManualAmount[client])
					{
						credits = 2*g_iManualAmount[client];
						CPrintToChat(client, "%s You won \x04%d\x01 Credits", PREFIX,(credits/2));
					}
					else if(credits != g_iManualAmount[client])
						CPrintToChat(client, "%s You won \x04%d\x01 Credits", PREFIX,credits);
	
					Store_SetClientCredits(client, Store_GetClientCredits(client) + credits);
				}
				else
					CPrintToChat(client, "%s You \x07lost\x01 your bet",PREFIX);

				PrintCenterText(client,"The next number was: \x10%d", g_iRand2);
				CPrintToChat(client,"%s The next number was: \x10%d", PREFIX,g_iRand2);
			}
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (g_bTypingAmount[client])
	{
		if (IsNumeric(sArgs))
		{
			int iMinAmount = g_cvMinAmount.IntValue;
			int iMaxAmount = g_cvMaxAmount.IntValue;
			int iAmount = StringToInt(sArgs);
			if (iAmount < iMinAmount)
			{
				PrintToChat(client, "%s Minimum amount of Credits is \x10%i", PREFIX, iMinAmount);
				return Plugin_Handled;
			}
			else if (iAmount > iMaxAmount)
			{
				PrintToChat(client, "%s Maximum amount of Credits is \x10%i", PREFIX, iMaxAmount);
				return Plugin_Handled;
			}
			g_iManualAmount[client] = iAmount;
			PrintToChat(client, "%s You chose \x10%i\x01 Credits to play with", PREFIX, iAmount);
		}
		else
			PrintToChat(client, "%s You can type only numbers..", PREFIX);
		
		ShowMainMenu(client);
		g_bTypingAmount[client] = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool IsNumeric(const char[] buffer)
{
	int iLen = strlen(buffer);
	for (int i = 0; i < iLen; i++)
	{
		if (!IsCharNumeric(buffer[i]))
			return false;
	}
	return true;
}

void ShowMainMenu(int client)
{
	Menu HolMenu = new Menu(menuHandler_HolMenu);
	HolMenu.SetTitle("%s High or Low", MENUPREFIX);
	char szItem1[64];
	Format(szItem1, sizeof(szItem1), "Current Amount : %i\n[Press to Change]", g_iManualAmount[client]);
	HolMenu.AddItem("", szItem1);
	HolMenu.AddItem("", "Start!");
	HolMenu.ExitButton = true;
	HolMenu.Display(client, MENU_TIME_FOREVER);
}