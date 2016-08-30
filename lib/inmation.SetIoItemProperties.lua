local ioItemsCount = 0
local ioNodesCount = 0
local uaDatasources = 0
local conn_path = "/System/INMWS005/localhost"

-- Function to recursively work the tree
function SetChildrenProperties(parent)
	local children = parent:children()
	for _,child in pairs(children) do
		if child:type() == "MODEL_CLASS_IOITEM" then
		
			-- Script runtime information
			ioItemsCount = ioItemsCount + 1
			inmation.setvalue("A", ioItemsCount)
			
			-- Set SamplingRate property
			child.IoTypeOpcUa.OpcUaMonitoredItemParams.OpcUaRequestedSamplingRate = 1000
			child:commit()
		end
		if child:type() == "MODEL_CLASS_IONODE" then
			ioNodesCount = ioNodesCount + 1
		end
		SetChildrenProperties(child)
	end
end

-- MAIN EXECUTION..

inmation.setvalue("/System/INMWS005/SetObjectProperties_Worker", "RUNNING...")
inmation.setvalue("/System/INMWS005/SetObjectProperties_IoItemsProcessed", 0)

-- Get connector object, and loop all datasources below
local conn = inmation.getobject(conn_path)
local children = conn:children()
for _,child in pairs(children) do
	if child:type() == "MODEL_CLASS_DATASOURCE" then
		if (child.ServerType == 1) then
			uaDatasources = uaDatasources + 1
			
			SetChildrenProperties(child)
		end
	end
end

return "...DONE UA Sources: " .. uaDatasources .. " Nodes: " .. ioNodesCount .. " Items: " .. ioItemsCount