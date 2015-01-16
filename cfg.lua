    local addonName, ns = ...
    local _, class = UnitClass("player")
    local mediaPath = "Interface\\AddOns\\oUF_Kygo\\Media\\"
     
    local cfg = {
       texture = mediaPath.."normTex2.tga",
       bgFile = mediaPath.."backdrop",
       edgeFile = mediaPath.."backdrop_edge",
       Icon = mediaPath.."Neal_border",
       CPoint = mediaPath.."NCPoint",
       font = "Interface\\AddOns\\oUF_Kygo\\Media\\Fonts\\Homespun.ttf",
       fontsize = 10,
       fontflag = "OUTLINE, MONOCHROME", -- Font flags should be in capitals and separated by a comma
 }   
     
    ns.cfg = cfg