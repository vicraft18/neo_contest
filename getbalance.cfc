<cfcomponent name="neo" extends="coldbox.system.eventhandler" autowire="true" output="false">
	<cffunction name="get_all_address" access="public" returntype="any">
		<cfargument name="Event" type="coldbox.system.beans.requestContext">
		<cfset var rc = Event.getCollection() />
		<cfset var result = StructNew() />
		<cfset var db_result = StructNew() />
		<cfset var jsonp_data = '' />
		<cfset var run_result = '' />
		<cfset var auth_result = "" />
		<cfset var auth_result2 = "" />
		<cfset var api_url = "" />
		<cfset var api_url2 = "" />
		<cfset var temp_vin_index = "" />
		<cfset var temp_vin = "" />

		<cfset var api_body = "" />
		<cfset var temp_vout = "" />
		<!---
		<cfset var start_height = 0 />
		<cfset var block_height = 5000 />
		--->
		<cfset var start_height = rc.start_height />
		<cfset var block_height = rc.block_height />
		
		<cfset var i = 0 />
		<cfset var j = 1 />
		<cfset var k = 1 />
		<cfset var m = 1 />
		<cfset result_list = StructNew() />
		
		
		<cfloop index = "i"	from = "#start_height#" to = "#block_height#"	step = "1"> 
			<cfset api_url = "http://127.0.0.1:10332/?jsonrpc=2.0&method=getblock&params=[#i#,1]&id=1" />
		
			<cfhttp url="#api_url#" method="GET" result="auth_result">	
			</cfhttp>
			
		
			<cfset temp_vout = DeserializeJSON(auth_result.filecontent) />
			<!---
			<cfdump var = "#temp_vout#" />
			--->
			
		
			<cfif arraylen(temp_vout.result.tx) gt 1>
				<cfset j = 1 />
				<cfloop index = "j"	from = "1" to = "#arraylen(temp_vout.result.tx)#" step = "1"> 
				
					<cfif arraylen(temp_vout.result.tx[j].vout) gt 0>
						<cfset k = 1 />
						
						<cfloop index = "k"	from = "1" to = "#arraylen(temp_vout.result.tx[j].vout)#" step = "1"> 
							<cfif temp_vout.result.tx[j].vout[k].asset eq "0xc56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b">
								<cfif not StructKeyExists(result_list,temp_vout.result.tx[j].vout[k].address)>
									<cfset result_list[temp_vout.result.tx[j].vout[k].address] = LSParseNumber(temp_vout.result.tx[j].vout[k].value) />
									
								<cfelse>
									<cfset result_list[temp_vout.result.tx[j].vout[k].address] = result_list[temp_vout.result.tx[j].vout[k].address] + LSParseNumber(temp_vout.result.tx[j].vout[k].value) />
								
								</cfif>
							</cfif>
						</cfloop>
						
					</cfif>
					
					<cfif arraylen(temp_vout.result.tx[j].vin) gt 0>
						<cfset m = 1 />
						<cfloop index = "m"	from = "1" to = "#arraylen(temp_vout.result.tx[j].vin)#" step = "1"> 
							<cfset api_url2 = 'http://127.0.0.1:10332/?jsonrpc=2.0&method=getrawtransaction&params=["#temp_vout.result.tx[j].vin[m].txid#",1]&id=1' />
							<cfset temp_vin_index = temp_vout.result.tx[j].vin[m].vout />
							<cfhttp url="#api_url2#" method="GET" result="auth_result2">	
							</cfhttp>
							<cfset temp_vin = DeserializeJSON(auth_result2.filecontent) />
							
							<!---
							<cfdump var="#temp_vin#" />
							--->
							
							<cfif temp_vin.result.vout[temp_vin_index+1].asset eq "0xc56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b" && temp_vin.result.vout[temp_vin_index+1].value neq "0">
								<cfif not StructKeyExists(result_list,temp_vin.result.vout[temp_vin_index+1].address)>
									<cfset result_list[temp_vin.result.vout[temp_vin_index+1].address] = LSParseNumber(temp_vin.result.vout[temp_vin_index+1].value) * -1 />
									
								<cfelse>
									<cfset result_list[temp_vin.result.vout[temp_vin_index+1].address] = result_list[temp_vin.result.vout[temp_vin_index+1].address] - LSParseNumber(temp_vin.result.vout[temp_vin_index+1].value) />
								
								</cfif>
							</cfif>
						</cfloop>
					</cfif>
				
				</cfloop>
				

			</cfif>
			
			
		</cfloop>
		
			<cfquery name="menuData" datasource="neo">
				<cfloop collection="#result_list#" item="key">
					<cfif result_list[key] neq 0>
						insert into neo (address,value,start_block,end_block,input_date) values ('#key#','#result_list[key]#',#start_height#,#block_height#,getdate())
					</cfif>
				</cfloop>
			</cfquery>
		
	
		<cfdump var = "success" />
		<cfabort />
		
		<cfset json = CreateObject("component","coldext.json.json") />
		<cfset Event.setValue("jsonp_data",'{"flag":"0","message":""}') />
		<cfset Event.setView("jsonp_data",true) />
	</cffunction>
	
	
	<cffunction name="export_csv" access="public" returntype="any">
		<cfargument name="Event" type="coldbox.system.beans.requestContext">
		<cfset var rc = Event.getCollection() />
	
		
		<cfquery name="menuData" datasource="neo">
			select * from neo order by value desc
		</cfquery>
				
			
		
		<cfsavecontent variable="content">
			<cfprocessingdirective suppresswhitespace="yes">
			
			<cfloop query = "menuData"> 
					<cfoutput>
						 #address#,#value#
					</cfoutput>
			</cfloop>
			
			</cfprocessingdirective>
		</cfsavecontent>
		

		<cffile file="D:\neo_address_balance.csv" action="write" nameconflict="overwrite" output="#content#" addnewline="no">
			

		<cfdump var = "success" />
		<cfabort />
		
		<cfset json = CreateObject("component","coldext.json.json") />
		<cfset Event.setValue("jsonp_data",'{"flag":"0","message":""}') />
		<cfset Event.setView("jsonp_data",true) />
	</cffunction>

	
	
	
</cfcomponent>








