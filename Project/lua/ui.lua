-----------------------------------------------------------------------------------------
--
-- ui.lua
--
-----------------------------------------------------------------------------------------
module(..., package.seeall)

function generateWindow(width, height, title, description)

	local window = display.newGroup()
	window.x = display.contentCenterX
	window.y = display.contentCenterY
	
	window.top = height/-2
	window.down = height/2
	window.left = width/-2
	window.right = width/2
	
	window.back = display.newRect(0, 0, width, height)
	window.back.strokeWidth = 4
	window.back:setFillColor(0.2,0.2,0.2,1)
	window:insert(window.back)
	
	window.titleText = display.newText(title, 0, window.top+20, "Consolas", 25)
	window:insert(window.titleText)
	
	window.descriptionText = display.newText(description, 0, window.top+75, "Consolas", 20)
	window:insert(window.descriptionText)
end

function generateBar(info, isPercent)
	local width = info.width or display.contentWidth
	local height = info.height or 10
	local x = info.x or info.left_x+(width/2) or display.contentCenterX
	local y = info.y or info.top_y+(height/2) or (0+(height/2))
	local label = info.label or ""
	local colors = info.colors or { }
	local fontSize = info.fontSize or 18
	
	colors["BACK"] = colors["BACK"] or {0,0,0,0}
	colors["LABEL"] = colors["LABEL"] or {1,1,1,1}
	colors["BAR"] = colors["BAR"] or colors["FILL"] or {0.8,0.8,0.8,1}
	colors["FIXED"] = colors["FIXED"] or colors["DARK"] or {0.5,0.5,0.5,1}
	colors["VAR"] = colors["VAR"] or colors["LIGHT"] or colors["DARK"] or {0.5,0.5,0.5,1}
	
	local barGroup = display.newGroup()
	barGroup.x = x
	barGroup.y = y
	
	barGroup.percent = 1.0
	barGroup.displayText = ""
	barGroup.isPercent = isPercent
	
	barGroup.labelWidth = label:len() * (fontSize-6)
	barGroup.left = width/-2
	barGroup.right = width/2
	barGroup.leftBar = barGroup.left+barGroup.labelWidth
	barGroup.centerBar = barGroup.leftBar + (barGroup.right - barGroup.leftBar)/2
	
	barGroup.backFill = display.newRect(0,0,width,height)
	barGroup.backFill:setFillColor(unpack(colors["BACK"]))
	barGroup:insert(barGroup.backFill)
	
	barGroup.label = display.newText(label, barGroup.left, 0, "Consolas", fontSize)
	barGroup.label:setFillColor(unpack(colors["LABEL"]))
	barGroup.label.anchorX = 0
	barGroup:insert(barGroup.label)
	
	barGroup.bar = display.newRect(barGroup.leftBar,0,width-barGroup.labelWidth,height)
	barGroup.bar:setFillColor(unpack(colors["BAR"]))
	barGroup.bar.maxWidth = width-barGroup.labelWidth
	barGroup.bar.anchorX = 0
	barGroup:insert(barGroup.bar)
	
	barGroup.varCap = display.newRect(barGroup.right,0,5,height)
	barGroup.varCap:setFillColor(unpack(colors["VAR"]))
	barGroup.varCap.anchorX = 0
	barGroup:insert(barGroup.varCap)
	
	barGroup.fixedCap = display.newRect(barGroup.right,0,2,height)
	barGroup.fixedCap:setFillColor(unpack(colors["FIXED"]))
	barGroup.fixedCap.anchorX = 1
	barGroup:insert(barGroup.fixedCap)
	
	barGroup.text = display.newText(barGroup.displayText,barGroup.centerBar,0,"Consolas",fontSize-2)
	barGroup.text:setFillColor(unpack(colors["FIXED"]))
	barGroup:insert(barGroup.text)
	
	barGroup.update = function(self, current, maximum)
		
		newPercent = (math.floor((current/maximum)*1000))/1000
		
		local maxDelta = 0.005
		local delta = newPercent - self.percent
		if (delta > maxDelta) then
			delta = maxDelta
		end
		
		if (delta ~= 0) then
			if (delta < 0) then
				delta = 1 - self.percent
				if (delta > maxDelta) then
					delta = maxDelta
				end
			end
			
			self.percent = self.percent + delta
			
			if (self.percent >= 1) then
				self.percent = 0
			end
		end
		self.bar.width = self.bar.maxWidth*self.percent
		self.fixedCap.x = self.right - self.bar.maxWidth*(1.0-self.percent)
		
		if (self.isPercent) then
			barGroup.displayText = math.floor(barGroup.percent*100).."%"
		else
			barGroup.displayText = current.."/"..maximum
		end
		barGroup.text.text = barGroup.displayText
	end
	
	return barGroup
end



