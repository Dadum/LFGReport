LFClean = LibStub("AceAddon-3.0"):NewAddon("LFClean", "AceConsole-3.0",
                                           "AceEvent-3.0")
GUI = LibStub("AceGUI-3.0")

-- * --------------------------------------------------------------------------
-- * Init
-- * --------------------------------------------------------------------------

function LFClean:OnInitialize()
    self.buttons = {}
    self.selectedButton = nil

    LFClean:InitConfig()
    LFClean:InitDB()
end

-- * --------------------------------------------------------------------------
-- * LFClean utility
-- * --------------------------------------------------------------------------

-- * Report the group with the given id.
function LFClean:Report(id)
    local panel = _G.LFGListFrame.SearchPanel
    if id then
        local details = C_LFGList.GetSearchResultInfo(id)

            C_LFGList.ReportSearchResult(id, "lfglistspam");
        self:Print("Reported group: " .. details.name);

        LFGListSearchPanel_UpdateResultList(panel);
        LFGListSearchPanel_UpdateResults(panel);
    else
        self:Print("No group selected")
    end
end

-- * Generate a tooltip to show the selected group id
function LFClean:GenerateReportTooltip(id)
    local details = C_LFGList.GetSearchResultInfo(id)
    GameTooltip:AddLine("Report group: " .. details.name, nil, nil, nil, --[[wrapText]] true)
    GameTooltip:AddLine("Group id: " .. id, 1, 1, 1, --[[wrapText]] true)
    GameTooltip:Show()
end

-- * Generate report button for each entry in the LFG list
function LFClean:GenerateEntryButtons()
    local panel = _G.LFGListFrame.SearchPanel
    if (self.conf.profile.entryButtons) then
        for i = 1, #panel.ScrollFrame.buttons do
            -- Only generate a button if it is missing
            if self.buttons[i] == nil then
                self.buttons[i] = CreateFrame("Button", "btn" .. i,
                                              panel.ScrollFrame.buttons[i],
                                              "UIPanelSquareButton")
                self.buttons[i]:SetPoint("RIGHT", panel.ScrollFrame.buttons[i],
                                         "RIGHT", -1, -1)
                self.buttons[i]:SetSize(25, 25)
                self.buttons[i]:SetAlpha(1)
                self.buttons[i]:SetScript("OnClick", function(self)
                    LFClean:Report(self:GetParent().resultID)
                end)
                self.buttons[i]:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                    LFClean:GenerateReportTooltip(self:GetParent().resultID)
                end)
                self.buttons[i]:SetScript("OnLeave", GameTooltip_Hide)
            end

            -- Hide the button if currently queued for the group
            if panel.ScrollFrame.buttons[i].PendingLabel:IsShown() then
                self.buttons[i]:Hide()
            else
                self.buttons[i]:Show()
            end

            -- Anchor DataDisplay to the report button
            panel.ScrollFrame.buttons[i].DataDisplay:ClearAllPoints()
            panel.ScrollFrame.buttons[i].DataDisplay:SetPoint("RIGHT",
                                                              self.buttons[i],
                                                              "LEFT", 10, -1)

            -- Set new max name width to avoid overlapping
            if panel.ScrollFrame.buttons[i].resultID then
                local details = _G.C_LFGList.GetSearchResultInfo(
                                    panel.ScrollFrame.buttons[i].resultID)
                local nameWidth = details.voiceChat == "" and 155 or 133
                if (panel.ScrollFrame.buttons[i].Name:GetWidth() > nameWidth) then
                    panel.ScrollFrame.buttons[i].Name:SetWidth(nameWidth)
                end
            end
        end
    else
        for i = 1, #self.buttons do
            self.buttons[i] = nil
            -- Reset DataDisplay to original anchor
            panel.ScrollFrame.buttons[i].DataDisplay:ClearAllPoints()
            panel.ScrollFrame.buttons[i].DataDisplay:SetPoint("RIGHT",
                                                              panel.ScrollFrame
                                                                  .buttons[i],
                                                              "RIGHT", 0, -1)
        end
    end
end

-- * Generate button to report the selected group
function LFClean:GenerateSelectedButton()
    if (self.conf.profile.selectedButton) then
        local panel = _G.LFGListFrame.SearchPanel
        if (self.selectedButton == nil) then
            self.selectedButton = CreateFrame("Button", "btn",
                                              _G.LFGListFrame.SearchPanel,
                                              "UIPanelSquareButton")
            self.selectedButton:SetPoint("RIGHT", _G.LFGListFrame.SearchPanel
                                             .RefreshButton, "LEFT", -5, 0)
            self.selectedButton:SetSize(25, 25)
            self.selectedButton:SetScript("OnClick", function()
                -- Report currently selected entry
                local id = panel.selectedResult
                LFClean:Report(id)

                -- Remove selection
                panel.selectedResult = nil
            end)
            self.selectedButton:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                if (panel.selectedResult) then
                    LFClean:GenerateReportTooltip(panel.selectedResult)
                else
                    GameTooltip:SetText("Select a group to report")
                end
            end)
            self.selectedButton:SetScript("OnLeave", GameTooltip_Hide)
        end
        self.selectedButton:Show()
    else
        if (self.selectedButton) then self.selectedButton:Hide() end
    end
end

-- * --------------------------------------------------------------------------
-- * Events handling
-- * --------------------------------------------------------------------------

function LFClean:OnReceiveSearchResults()
    self:GenerateSelectedButton()
    self:GenerateEntryButtons()
end

LFClean:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED",
                      "OnReceiveSearchResults")

LFClean:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED",
                      "GenerateEntryButtons")
