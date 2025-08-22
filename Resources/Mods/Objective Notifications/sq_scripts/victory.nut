class VictoryCheckAux extends SqRootScript
{
// METHODS:

	function GoalStateVarName(i)
	{
	   return format("GOAL_STATE_%d", i);
	}

	function GoalVisibleVarName(i)
	{
	   return format("GOAL_VISIBLE_%d", i);
	}

	function GoalMinDiffVarName(i)
	{
		return format("GOAL_MIN_DIFF_%d" ,i); 
	}

	function GoalMaxDiffVarName(i)
	{
		return format("GOAL_MAX_DIFF_%d" ,i); 
	}

	function ObjectiveExists(objective)
	{
		return Quest.Exists( GoalStateVarName(objective) );
	}

	function ObjectiveVisible(objective)
	{
		local mindiff = GoalMinDiffVarName(objective);
		local maxdiff = GoalMaxDiffVarName(objective);
		local difficulty = Quest.Get("difficulty");

		if (Quest.Exists(mindiff) && difficulty < Quest.Get(mindiff))
			return false;

		if (Quest.Exists(maxdiff) && difficulty > Quest.Get(maxdiff))
			return false;

		return Quest.Get( GoalVisibleVarName(objective) );
	}

	function CheckObjectiveCompleted(qvar, oldval, newval)
	{
		//if (newval != eGoalState.kGoalComplete || DarkGame.BindingGetFloat("goal_notify") == 0.0)
		if (newval != eGoalState.kGoalComplete)
			return;

		// convert qvar to lower case for case insensitive compare below
		qvar = qvar.tolower();

		for (local goal=0; ObjectiveExists(goal); goal++)
		{
			if (ObjectiveVisible(goal) && qvar == GoalStateVarName(goal).tolower())
			{
				// found an objective that just completed

				// to avoid false positives with goal type 4 objectives, which in some missions are set then
				// immediately unset again, we introduce a short delay and check the completion a second time
				SetOneShotTimer("DelayedObjCheck", 0.01, goal)
			}
		}
	}

	function Ding(curtime)
	{
		// don't do more than one notification per frame
		if (GetData("LastDingTime") == curtime)
			return;

		SetData("LastDingTime", curtime);

		local s = Data.GetString("PlayHint.str", "DoneGoal");
		if (!s || s == "")
			s = "Objective Complete";
		DarkUI.TextMessage(s);

		Sound.PlaySchemaAmbient(self, "new_obj");
	}

// MESSAGES:

	// we don't subscribe to qvars in this script, instead we rely on the VictoryCheck script, that should be assigned
	// to the same object as this script, to have subscribed to all the necessary qvars
	function OnQuestChange()
	{
		//print("Quest " + message().m_pName + " change " + message().m_oldValue + " to " + message().m_newValue);

		if (message().m_oldValue != message().m_newValue)
		{
			CheckObjectiveCompleted(message().m_pName, message().m_oldValue, message().m_newValue);
		}
	}

	function OnTimer()
	{
		if (message().name == "DelayedObjCheck")
		{
			local goal = message().data;

			if (Quest.Get( GoalStateVarName(goal) ) == eGoalState.kGoalComplete)
				Ding(message().time);
		}
	}
}
