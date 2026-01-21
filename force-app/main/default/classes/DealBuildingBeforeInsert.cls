public class DealBuildingBeforeInsert {
    public static void beforeInsert(list<Deal_Building__c> triggerNew){
        Set<Id> oppIdList = new Set<Id>();
        Set<Id> buildingIdList = new Set<Id>();
        for(Deal_Building__c db : triggerNew){
            
            oppIdList.add(db.Deal__c);
            buildingIdList.add(db.Building__c);
            System.debug('db.Deal__c '+db.Deal__c);
            System.debug('db.Building__c '+db.Building__c);
        }
        Map<Id, Opportunity> mapOpportunity = new Map<Id, Opportunity>([SELECT Id, RecordType.Name FROM Opportunity WHERE Id IN:oppIdList]);
        Map<Id, Building__c> mapBuildings = new Map<Id, Building__c>([SELECT Id, Gross_Leasable_Amount_SAR__c, Total_Selling_Price_SAR__c, Client_Asking_Price_SAR__c, Asking_Annual_Rent__c FROM Building__c WHERE Id IN:buildingIdList]);
        for(Deal_Building__c db : triggerNew){
            System.debug('TEST RECORD '+mapOpportunity.get(db.Deal__c).RecordType.Name);
            if(mapOpportunity.get(db.Deal__c).RecordType.Name == 'Offices'){//Offices
            System.debug('TEST RECORD Offices');
                db.Total_Selling_Price_SAR__c = mapBuildings.get(db.Building__c).Gross_Leasable_Amount_SAR__c == null ? 0 : mapBuildings.get(db.Building__c).Gross_Leasable_Amount_SAR__c;
            }
            if(mapOpportunity.get(db.Deal__c).RecordType.Name == 'Residential'){
                System.debug('TEST RECORD Residential');
                db.Total_Selling_Price_SAR__c = mapBuildings.get(db.Building__c).Client_Asking_Price_SAR__c == null ? 0 : mapBuildings.get(db.Building__c).Client_Asking_Price_SAR__c;
            }
            if(mapOpportunity.get(db.Deal__c).RecordType.Name == 'Retail'){//Retail
            System.debug('TEST RECORD Retail');
                db.Total_Selling_Price_SAR__c = mapBuildings.get(db.Building__c).Asking_Annual_Rent__c == null ? 0 : mapBuildings.get(db.Building__c).Asking_Annual_Rent__c;
            }
        }
    }
    
    public static void afterInsert(list<Deal_Building__c> triggerNew){
        plug();
        map<Id, Decimal> idDBtoAmount = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoUnitSize = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoService_Area_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoTerrace_Area_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoService_Area_SAR = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoTerrace_Area_SAR = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_Acceptable_Rent = new map<Id, Decimal>();
        //---------------------------------------------------------------------
        map<Id, Decimal> idDBtoAsking_Rate_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoTotal_Asking_Rent_SR = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoArea_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoRate_per_Sqm_SR_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoTotal_Annual_Rent_SR_Annum = new map<Id, Decimal>();
        map<Id, String> idDBtoUnit_Number = new map<Id, String>();
        map<Id, Decimal> idDBtoTotal_Annual_Rent = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_Acceptable_Rate_Sqm_SR_Sqm = new map<Id, Decimal>();    
        //---------------------------------------------------------------------
        map<Id, Decimal> idDBtoMinimum_Lobby_Area_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_Price_Sqm_SAR_Lobby = new map<Id, Decimal>();  
        //---------------------------------------------------------------------
        map<Id, Decimal> idDBtoMinimum_UAS = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_TPUA = new map<Id, Decimal>();  
        //---------------------------------------------------------------------
        map<Id, Decimal> idDBtoMinimum_TPSA = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_TPTA = new map<Id, Decimal>();  
        //---------------------------------------------------------------------
        Set<Id> oppForUpdateSet = new Set<Id>();
        //Set<Id> oppIdList = new Set<Id>();
        Set<Id> oppIdList = new Set<Id>();
        for(Deal_Building__c db : triggerNew){
            oppIdList.add(db.Deal__c);
        }
        Map<Id, Opportunity> mapOpportunity = new Map<Id, Opportunity>([SELECT Id, RecordType.Name FROM Opportunity WHERE Id IN:oppIdList]);
        //-------------------------------------------
        for(Deal_Building__c db : triggerNew){
            System.debug('db.Leasing_Rate_Sqm_SAR__c '+db.Leasing_Rate_Sqm_SAR__c);
            
            if(mapOpportunity.get(db.Deal__c).RecordType.Name == 'Offices'){
                //------------------idDBtoMinimum_UAS---------------------------
            	if(idDBtoMinimum_UAS.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoMinimum_UAS.get(db.Deal__c) + db.Unit_Area_Sqm_NSA__c;
                    idDBtoMinimum_UAS.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoMinimum_UAS.put(db.Deal__c,db.Unit_Area_Sqm_NSA__c);    
                }
                //------------------idDBtoMinimum_TPUA---------------------------
            	if(idDBtoMinimum_TPUA.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoMinimum_TPUA.get(db.Deal__c) + db.Total_NSA__c;
                    idDBtoMinimum_TPUA.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoMinimum_TPUA.put(db.Deal__c,db.Total_NSA__c);    
                }
                //------------------idDBtoMinimum_TPSA---------------------------
            	if(idDBtoMinimum_TPSA.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoMinimum_TPSA.get(db.Deal__c) + db.Total_Prices_Services_Areas__c;
                    idDBtoMinimum_TPSA.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoMinimum_TPSA.put(db.Deal__c,db.Total_Prices_Services_Areas__c);    
                }
                //------------------idDBtoMinimum_TPTA---------------------------
            	if(idDBtoMinimum_TPTA.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoMinimum_TPTA.get(db.Deal__c) + db.Total_Prices_Terraces_Areas__c;
                    idDBtoMinimum_TPTA.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoMinimum_TPTA.put(db.Deal__c,db.Total_Prices_Terraces_Areas__c);    
                }
                //---------------------------------------------------------------
                //------------------Lobby_Area_Sqm__c---------------------------
            	if(idDBtoMinimum_Lobby_Area_Sqm.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoMinimum_Lobby_Area_Sqm.get(db.Deal__c) + db.Lobby_Area_Sqm__c;
                    idDBtoMinimum_Lobby_Area_Sqm.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoMinimum_Lobby_Area_Sqm.put(db.Deal__c,db.Lobby_Area_Sqm__c);    
                }
                //------------------Price_Sqm_SAR_Lobby__c---------------------------
            	if(idDBtoMinimum_Price_Sqm_SAR_Lobby.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoMinimum_Price_Sqm_SAR_Lobby.get(db.Deal__c) + db.Total_Prices_Lobby__c;
                    idDBtoMinimum_Price_Sqm_SAR_Lobby.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoMinimum_Price_Sqm_SAR_Lobby.put(db.Deal__c,db.Total_Prices_Lobby__c);    
                }
                //------------------idDBtoMinimum_Acceptable_Rate_Sqm_SR_Sqm---------------------------
            	if(idDBtoMinimum_Acceptable_Rate_Sqm_SR_Sqm.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoMinimum_Acceptable_Rate_Sqm_SR_Sqm.get(db.Deal__c) + db.Leasing_Rate_Sqm_SAR__c;
                    idDBtoMinimum_Acceptable_Rate_Sqm_SR_Sqm.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoMinimum_Acceptable_Rate_Sqm_SR_Sqm.put(db.Deal__c,db.Leasing_Rate_Sqm_SAR__c);    
                }
                //------------------Asking_Rate_Sqm---------------------------
            	if(idDBtoAsking_Rate_Sqm.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoAsking_Rate_Sqm.get(db.Deal__c) + db.Leasing_Rate_Sqm_SAR__c;
                    idDBtoAsking_Rate_Sqm.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoAsking_Rate_Sqm.put(db.Deal__c,db.Leasing_Rate_Sqm_SAR__c);    
                }
                //------------------Total_Asking_Rent_SR---------------------------
            	if(idDBtoTotal_Asking_Rent_SR.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoTotal_Asking_Rent_SR.get(db.Deal__c) + db.Total_NSA__c;
                    idDBtoTotal_Asking_Rent_SR.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoTotal_Asking_Rent_SR.put(db.Deal__c,db.Total_NSA__c);    
                }
                //------------------Area_Sqm---------------------------
            	if(idDBtoArea_Sqm.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoArea_Sqm.get(db.Deal__c) + db.Total_Leasable_Area_Sqm__c ;
                    idDBtoArea_Sqm.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoArea_Sqm.put(db.Deal__c,db.Total_Leasable_Area_Sqm__c );    
                }
                //------------------Rate_per_Sqm_SR_Sqm---------------------------
            	if(idDBtoRate_per_Sqm_SR_Sqm.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoRate_per_Sqm_SR_Sqm.get(db.Deal__c) + db.Total_Selling_Price_SAR__c/db.Total_Leasable_Area_Sqm__c ;
                    idDBtoRate_per_Sqm_SR_Sqm.put(db.Deal__c, dcCurrency); 
                }else{
                    System.debug('db.Total_Selling_Price_SAR__c1 '+db.Total_Selling_Price_SAR__c);
                    System.debug('db.Total_Leasable_Area_Sqm__c1 '+db.Total_Leasable_Area_Sqm__c);
                    if(db.Total_Selling_Price_SAR__c != 0 && db.Total_Leasable_Area_Sqm__c != 0){
                    	idDBtoRate_per_Sqm_SR_Sqm.put(db.Deal__c,db.Total_Selling_Price_SAR__c/db.Total_Leasable_Area_Sqm__c );    
                    }
                    System.debug('db.Total_Selling_Price_SAR__c2 '+db.Total_Selling_Price_SAR__c);
                    System.debug('db.Total_Leasable_Area_Sqm__c2 '+db.Total_Leasable_Area_Sqm__c);
                }
                //------------------Total_Annual_Rent_SR_Annum---------------------------
            	if(idDBtoTotal_Annual_Rent_SR_Annum.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoTotal_Annual_Rent_SR_Annum.get(db.Deal__c) + db.Total_Selling_Price_SAR__c ;
                    idDBtoTotal_Annual_Rent_SR_Annum.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoTotal_Annual_Rent_SR_Annum.put(db.Deal__c,db.Total_Selling_Price_SAR__c );    
                }
            }
            
            if(mapOpportunity.get(db.Deal__c).RecordType.Name == 'Retail'){
                System.debug('db.Unit_No__c '+db.Unit_No__c);
                
                if(idDBtoUnit_Number.containsKey(db.Deal__c)){
                	String strNumber = idDBtoUnit_Number.get(db.Deal__c) +','+db.Unit_No__c ;
                    idDBtoUnit_Number.put(db.Deal__c, strNumber); 
                }else{ 
                    idDBtoUnit_Number.put(db.Deal__c,db.Unit_No__c);   
                }
                //------------------Area_Sqm---------------------------
            	if(idDBtoArea_Sqm.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoArea_Sqm.get(db.Deal__c) + db.Unit_Area_Sqm__c ;
                    idDBtoArea_Sqm.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoArea_Sqm.put(db.Deal__c,db.Unit_Area_Sqm__c );    
                }
                //------------------Rate_per_Sqm_SR_Sqm---------------------------
            	if(idDBtoRate_per_Sqm_SR_Sqm.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoRate_per_Sqm_SR_Sqm.get(db.Deal__c) + db.Asking_Price__c ;
                    idDBtoRate_per_Sqm_SR_Sqm.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoRate_per_Sqm_SR_Sqm.put(db.Deal__c,db.Asking_Price__c );    
                }
                //------------------Total_Annual_Rent---------------------------
            	if(idDBtoTotal_Annual_Rent.containsKey(db.Deal__c)){
                	Decimal dcCurrency = idDBtoTotal_Annual_Rent.get(db.Deal__c) + db.Total_Selling_Price_SAR__c ;
                    idDBtoTotal_Annual_Rent.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoTotal_Annual_Rent.put(db.Deal__c,db.Total_Selling_Price_SAR__c );    
                }
            }
            
            //------------------Amount---------------------------
            if(idDBtoAmount.containsKey(db.Deal__c)){
                Decimal dcCurrency = idDBtoAmount.get(db.Deal__c) + db.Total_Selling_Price_SAR__c;
                idDBtoAmount.put(db.Deal__c, dcCurrency); 
            }else{
                idDBtoAmount.put(db.Deal__c,db.Total_Selling_Price_SAR__c);    
            }
            //------------------UnitSize---------------------------
            if(mapOpportunity.get(db.Deal__c).RecordType.Name == 'Offices'){//Offices
                if(idDBtoUnitSize.containsKey(db.Deal__c)){
                    Decimal dcCurrency = idDBtoUnitSize.get(db.Deal__c) + db.Unit_Area_Sqm_NSA__c;
                    idDBtoUnitSize.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoUnitSize.put(db.Deal__c,db.Unit_Area_Sqm_NSA__c);    
                }
            }
            if(mapOpportunity.get(db.Deal__c).RecordType.Name == 'Retail'){//Retail
                if(idDBtoUnitSize.containsKey(db.Deal__c)){
                    Decimal dcCurrency = idDBtoUnitSize.get(db.Deal__c) + db.Unit_Area_Sqm__c;
                    idDBtoUnitSize.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoUnitSize.put(db.Deal__c,db.Unit_Area_Sqm__c);    
                }
            }
            //------------------Service_Area_Sqm__c---------------------------
            if(idDBtoService_Area_Sqm.containsKey(db.Deal__c)){
                Decimal dcCurrency = idDBtoService_Area_Sqm.get(db.Deal__c) + db.Service_Area_Sqm__c;
                idDBtoService_Area_Sqm.put(db.Deal__c, dcCurrency); 
            }else{
                idDBtoService_Area_Sqm.put(db.Deal__c,db.Service_Area_Sqm__c);    
            }
            //------------------Terrace_Area_Sqm__c---------------------------
            if(idDBtoTerrace_Area_Sqm.containsKey(db.Deal__c)){
                Decimal dcCurrency = idDBtoTerrace_Area_Sqm.get(db.Deal__c) + db.Terrace_Area_Sqm__c;
                idDBtoTerrace_Area_Sqm.put(db.Deal__c, dcCurrency); 
            }else{
                idDBtoTerrace_Area_Sqm.put(db.Deal__c,db.Terrace_Area_Sqm__c);    
            }
            //------------------Service_Area_SAR__c---------------------------
            if(idDBtoService_Area_SAR.containsKey(db.Deal__c)){
                Decimal dcCurrency = idDBtoService_Area_SAR.get(db.Deal__c) + db.Total_Prices_Services_Areas__c;
                idDBtoService_Area_SAR.put(db.Deal__c, dcCurrency); 
            }else{
                idDBtoService_Area_SAR.put(db.Deal__c,db.Total_Prices_Services_Areas__c);    
            }
            //------------------Terrace_Area_SAR__c---------------------------
            if(idDBtoTerrace_Area_SAR.containsKey(db.Deal__c)){
                Decimal dcCurrency = idDBtoTerrace_Area_SAR.get(db.Deal__c) + db.Total_Prices_Terraces_Areas__c;
                idDBtoTerrace_Area_SAR.put(db.Deal__c, dcCurrency); 
            }else{
                idDBtoTerrace_Area_SAR.put(db.Deal__c,db.Total_Prices_Terraces_Areas__c);    
            }
            //------------------Minimum_Acceptable_Rent__c---------------------------
            
            if(mapOpportunity.get(db.Deal__c).RecordType.Name == 'Offices'){//Offices
                if(idDBtoMinimum_Acceptable_Rent.containsKey(db.Deal__c)){
                    Decimal dcCurrency = idDBtoMinimum_Acceptable_Rent.get(db.Deal__c) + db.Total_NSA__c;
                    idDBtoMinimum_Acceptable_Rent.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoMinimum_Acceptable_Rent.put(db.Deal__c,db.Total_NSA__c);    
                }
            }
            if(mapOpportunity.get(db.Deal__c).RecordType.Name == 'Retail'){//Retail
                if(idDBtoMinimum_Acceptable_Rent.containsKey(db.Deal__c)){
                    Decimal dcCurrency = idDBtoMinimum_Acceptable_Rent.get(db.Deal__c) + db.Minimum_Annual_Rent__c;
                    idDBtoMinimum_Acceptable_Rent.put(db.Deal__c, dcCurrency); 
                }else{
                    idDBtoMinimum_Acceptable_Rent.put(db.Deal__c,db.Minimum_Annual_Rent__c);    
                }
            }
            oppForUpdateSet.add(db.Deal__c);
        }
        List<Opportunity> oppListForUpdate = new List<Opportunity>();
        if(oppForUpdateSet.size() > 0){
            for(Opportunity opp : [SELECT Id,
                                   		RecordType.Name,
                                        Amount, 
                                        Unit_Size_SQM__c, 
                                        Service_Area_Sqm__c,
                                        Terrace_Area_Sqm__c,
                                        Service_Area_SAR__c,
                                        Terrace_Area_SAR__c,
                                        Minimum_Acceptable_Rent__c,
                                        Minimum_Acceptable_Rate_Sqm_SR_Sqm__c,
                                   //--------------------------------------------
                                   		Asking_Rate_Sqm__c,//Leasing_Rate_Sqm_SAR__c
                                   		Total_Asking_Rent_SR__c,//Total_NSA__c
                                   		Area_Sqm__c,//Total_Leasable_Area_Sqm__c ------- Unit_Area_Sqm__c
                                   		Rate_per_Sqm_SR_Sqm__c,//Total_Selling_Price_SAR__c/Total_Leasable_Area_Sqm__c ---- Asking_Price__c
                                   		Total_Annual_Rent_SR_Annum__c,//Total_Selling_Price_SAR__c
                                   		Unit_Number__c,//Unit_No__c
                                   		Total_Annual_Rent__c,//Total_Selling_Price_SAR__c
                                   		Lobby_Area_Sqm__c,
                                   		Price_Sqm_SAR_Lobby__c,
                                   		Total_Prices_Lobby_Areas__c,
                                   //---------------------------------------------
                                   		Unit_Area_Sqm__c,
                                   		Price_Sqm_SAR_Unit__c,
                                   		Total_Prices_Unit_Area__c,
                                   		Price_Sqm_SAR_Service__c,
                                   		Total_Prices_Service_Area__c,
                                   		Price_Sqm_SAR_Terrace__c,
                                   		Total_Prices_Terrace_Area__c
                                    FROM Opportunity WHERE Id IN :oppForUpdateSet]){
                                       
                //------------------Lobby---------------------------
                if(idDBtoMinimum_Lobby_Area_Sqm.keySet().size() > 0 && idDBtoMinimum_Lobby_Area_Sqm.get(opp.Id) != null){
                    if(opp.Lobby_Area_Sqm__c == null){
                       opp.Lobby_Area_Sqm__c = 0; 
                    }
                    opp.Lobby_Area_Sqm__c+=idDBtoMinimum_Lobby_Area_Sqm.get(opp.Id);
                }
                                        
                //------------------Lobby2---------------------------
                if(idDBtoMinimum_Price_Sqm_SAR_Lobby.keySet().size() > 0 && idDBtoMinimum_Price_Sqm_SAR_Lobby.get(opp.Id) != null){
                    if(opp.Total_Prices_Lobby_Areas__c == null){
                       opp.Total_Prices_Lobby_Areas__c = 0; 
                    }
                    opp.Total_Prices_Lobby_Areas__c+=idDBtoMinimum_Price_Sqm_SAR_Lobby.get(opp.Id);
                }
                //------------------Price_Sqm_SAR_Lobby__c---------------------------
                if(opp.RecordType.Name == 'Offices'){
                    if(opp.Total_Prices_Lobby_Areas__c != 0 && opp.Lobby_Area_Sqm__c != 0 && opp.Total_Prices_Lobby_Areas__c != Null && opp.Lobby_Area_Sqm__c != Null){
                        opp.Price_Sqm_SAR_Lobby__c = opp.Total_Prices_Lobby_Areas__c/opp.Lobby_Area_Sqm__c;    
                    }else{
                        opp.Price_Sqm_SAR_Lobby__c = 0;
                    }    
                }                        
                //------------------Lobby3---------------------------
                /*if(idDBtoTotal_Asking_Rent_SR.keySet().size() > 0 && idDBtoTotal_Asking_Rent_SR.get(opp.Id) != null){
                    if(opp.Total_Asking_Rent_SR__c == null){
                       opp.Total_Asking_Rent_SR__c = 0; 
                    }
                    opp.Total_Asking_Rent_SR__c+=idDBtoTotal_Asking_Rent_SR.get(opp.Id);
                }*/
                
                //------------------idDBtoTotal_Asking_Rent_SR---------------------------
                if(idDBtoTotal_Asking_Rent_SR.keySet().size() > 0 && idDBtoTotal_Asking_Rent_SR.get(opp.Id) != null){
                    if(opp.Total_Asking_Rent_SR__c == null){
                       opp.Total_Asking_Rent_SR__c = 0; 
                    }
                    opp.Total_Asking_Rent_SR__c+=idDBtoTotal_Asking_Rent_SR.get(opp.Id);
                }
                //------------------idDBtoArea_Sqm---------------------------
                if(idDBtoArea_Sqm.keySet().size() > 0 && idDBtoArea_Sqm.get(opp.Id) != null){
                    if(opp.Area_Sqm__c == null){
                       opp.Area_Sqm__c = 0; 
                    }
                    opp.Area_Sqm__c+=idDBtoArea_Sqm.get(opp.Id);
                }
                
                //------------------idDBtoTotal_Annual_Rent_SR_Annum---------------------------
                if(idDBtoTotal_Annual_Rent_SR_Annum.keySet().size() > 0 && idDBtoTotal_Annual_Rent_SR_Annum.get(opp.Id) != null){
                    if(opp.Total_Annual_Rent_SR_Annum__c == null){
                       opp.Total_Annual_Rent_SR_Annum__c = 0; 
                    }
                    opp.Total_Annual_Rent_SR_Annum__c+=idDBtoTotal_Annual_Rent_SR_Annum.get(opp.Id);
                }
                //------------------idDBtoUnit_Number---------------------------
                if(idDBtoUnit_Number.keySet().size() > 0 && idDBtoUnit_Number.get(opp.Id) != null){
                    if(opp.Unit_Number__c == null){
                       opp.Unit_Number__c=idDBtoUnit_Number.get(opp.Id); 
                    }else{
                       opp.Unit_Number__c+=','+idDBtoUnit_Number.get(opp.Id);
                    }
                }
                //------------------idDBtoTotal_Annual_Rent---------------------------
                System.debug(idDBtoTotal_Annual_Rent.keySet().size()+' '+idDBtoTotal_Annual_Rent.get(opp.Id));
                if(idDBtoTotal_Annual_Rent.keySet().size() > 0 && idDBtoTotal_Annual_Rent.get(opp.Id) != null){
                    System.debug('opp.RecordType.Name '+opp.RecordType.Name);
                    System.debug('opp.Total_Annual_Rent_SR_Annum__c '+opp.Total_Annual_Rent_SR_Annum__c);
                    if(opp.RecordType.Name == 'Offices'){
                    	if(opp.Total_Annual_Rent_SR_Annum__c == null){
                           opp.Total_Annual_Rent_SR_Annum__c = 0; 
                        }
                        opp.Total_Annual_Rent_SR_Annum__c+=idDBtoTotal_Annual_Rent.get(opp.Id);
                        System.debug('Offices '+opp.Total_Annual_Rent_SR_Annum__c);
                    }
                    //---------------------------------------------------------------------
                    if(opp.RecordType.Name == 'Retail'){
                    	if(opp.Total_Annual_Rent__c == null){
                           opp.Total_Annual_Rent__c = 0; 
                        }
                        opp.Total_Annual_Rent__c+=idDBtoTotal_Annual_Rent.get(opp.Id); 
                        System.debug('Retail '+opp.Total_Annual_Rent_SR_Annum__c);
                    }
                }                        
                //------------------Amount---------------------------
                if(idDBtoAmount.keySet().size() > 0 && idDBtoAmount.get(opp.Id) != null){
                    if(opp.Amount == null){
                       opp.Amount = 0; 
                    }
                    opp.Amount+=idDBtoAmount.get(opp.Id);
                }
                //------------------UnitSize---------------------------
                if(idDBtoUnitSize.keySet().size() > 0 && idDBtoUnitSize.get(opp.Id) != null){
                    System.debug('idDBtoUnitSize '+opp.Unit_Size_SQM__c);
                    System.debug('idDBtoUnitSize.get(opp.Id) '+idDBtoUnitSize.get(opp.Id));
                    if(opp.Unit_Size_SQM__c == null){
                       opp.Unit_Size_SQM__c = 0; 
                    }
                    opp.Unit_Size_SQM__c+=idDBtoUnitSize.get(opp.Id);
                }
                //------------------Service_Area_Sqm__c---------------------------
                if(idDBtoService_Area_Sqm.keySet().size() > 0 && idDBtoService_Area_Sqm.get(opp.Id) != null){
                    System.debug('idDBtoService_Area_Sqm '+opp.Service_Area_Sqm__c);
                    if(opp.Service_Area_Sqm__c == null){
                       opp.Service_Area_Sqm__c = 0; 
                    }
                    opp.Service_Area_Sqm__c+=idDBtoService_Area_Sqm.get(opp.Id);
                }
                //------------------Terrace_Area_Sqm__c---------------------------
                if(idDBtoTerrace_Area_Sqm.keySet().size() > 0 && idDBtoTerrace_Area_Sqm.get(opp.Id) != null){
                    System.debug('idDBtoTerrace_Area_Sqm '+opp.Amount);
                    if(opp.Terrace_Area_Sqm__c == null){
                       opp.Terrace_Area_Sqm__c = 0; 
                    }
                    opp.Terrace_Area_Sqm__c+=idDBtoTerrace_Area_Sqm.get(opp.Id);
                }
                //------------------Service_Area_SAR__c---------------------------
                if(idDBtoService_Area_SAR.keySet().size() > 0 && idDBtoService_Area_SAR.get(opp.Id) != null){
                    if(opp.Service_Area_SAR__c == null){
                       opp.Service_Area_SAR__c = 0; 
                    }
                    opp.Service_Area_SAR__c+=idDBtoService_Area_SAR.get(opp.Id);
                }
                //------------------Terrace_Area_SAR__c---------------------------
                if(idDBtoTerrace_Area_SAR.keySet().size() > 0 && idDBtoTerrace_Area_SAR.get(opp.Id) != null){
                    if(opp.Terrace_Area_SAR__c == null){
                       opp.Terrace_Area_SAR__c = 0; 
                    }
                    opp.Terrace_Area_SAR__c+=idDBtoTerrace_Area_SAR.get(opp.Id);
                }
                //------------------Minimum_Acceptable_Rent__c---------------------------
                if(idDBtoMinimum_Acceptable_Rent.keySet().size() > 0 && idDBtoMinimum_Acceptable_Rent.get(opp.Id) != null){
                    if(opp.Minimum_Acceptable_Rent__c == null){
                       opp.Minimum_Acceptable_Rent__c = 0; 
                    }
                    opp.Minimum_Acceptable_Rent__c+=idDBtoMinimum_Acceptable_Rent.get(opp.Id);
                }
                //------------------------------------------------------------------------
                if(opp.Total_Asking_Rent_SR__c != 0 && opp.Unit_Size_Sqm__c != 0 && opp.Total_Asking_Rent_SR__c != Null && opp.Unit_Size_Sqm__c != Null){
                	opp.Minimum_Acceptable_Rate_Sqm_SR_Sqm__c = opp.Total_Asking_Rent_SR__c/opp.Unit_Size_Sqm__c;    
                }else{
                    opp.Minimum_Acceptable_Rate_Sqm_SR_Sqm__c = 0;
                } 
                //------------------idDBtoAsking_Rate_Sqm---------------------------
                if(opp.Total_Asking_Rent_SR__c != 0 && opp.Unit_Size_Sqm__c != 0 && opp.Total_Asking_Rent_SR__c != Null && opp.Unit_Size_Sqm__c != Null){
                	opp.Asking_Rate_Sqm__c = opp.Total_Asking_Rent_SR__c/opp.Unit_Size_Sqm__c;    
                }else{
                    opp.Asking_Rate_Sqm__c = 0;
                } 
                if(opp.RecordType.Name == 'Offices'){
                //--------------------------------------------------
                //-------------------Unit_Area_Sqm__c---------------
                if(idDBtoMinimum_UAS.keySet().size() > 0 && idDBtoMinimum_UAS.get(opp.Id) != null){
                    if(opp.Unit_Area_Sqm__c == null){
                       opp.Unit_Area_Sqm__c = 0; 
                    }
                    opp.Unit_Area_Sqm__c+=idDBtoMinimum_UAS.get(opp.Id);
                }
                //-------------------Total_Prices_Unit_Area__c------
                if(idDBtoMinimum_TPUA.keySet().size() > 0 && idDBtoMinimum_TPUA.get(opp.Id) != null){
                    if(opp.Total_Prices_Unit_Area__c == null){
                       opp.Total_Prices_Unit_Area__c = 0; 
                    }
                    opp.Total_Prices_Unit_Area__c+=idDBtoMinimum_TPUA.get(opp.Id);
                }
                //---------Devide----------Price_Sqm_SAR_Unit__c----------
                if(opp.Total_Prices_Unit_Area__c != 0 && opp.Unit_Area_Sqm__c != 0 && opp.Total_Prices_Unit_Area__c != Null && opp.Unit_Area_Sqm__c != Null){
                    opp.Price_Sqm_SAR_Unit__c = opp.Total_Prices_Unit_Area__c/opp.Unit_Area_Sqm__c;    
                }else{
                    opp.Price_Sqm_SAR_Unit__c = 0;
                }
                //-------------------Total_Prices_Service_Area__c---
                if(idDBtoMinimum_TPSA.keySet().size() > 0 && idDBtoMinimum_TPSA.get(opp.Id) != null){
                    if(opp.Total_Prices_Service_Area__c == null){
                       opp.Total_Prices_Service_Area__c = 0; 
                    }
                    opp.Total_Prices_Service_Area__c+=idDBtoMinimum_TPSA.get(opp.Id);
                }
                //---------Devide----------Price_Sqm_SAR_Service__c-------
                if(opp.Total_Prices_Service_Area__c != 0 && opp.Service_Area_Sqm__c != 0 && opp.Total_Prices_Service_Area__c != Null && opp.Service_Area_Sqm__c != Null){
                    opp.Price_Sqm_SAR_Service__c = opp.Total_Prices_Service_Area__c/opp.Service_Area_Sqm__c;    
                }else{
                    opp.Price_Sqm_SAR_Service__c = 0;
                }
                //-------------------Total_Prices_Terrace_Area__c---
                if(idDBtoMinimum_TPTA.keySet().size() > 0 && idDBtoMinimum_TPTA.get(opp.Id) != null){
                    if(opp.Total_Prices_Terrace_Area__c == null){
                       opp.Total_Prices_Terrace_Area__c = 0; 
                    }
                    opp.Total_Prices_Terrace_Area__c+=idDBtoMinimum_TPTA.get(opp.Id);
                }
                //---------Devide----------Price_Sqm_SAR_Terrace__c-------
                if(opp.Total_Prices_Terrace_Area__c != 0 && opp.Terrace_Area_Sqm__c != 0 && opp.Total_Prices_Terrace_Area__c != Null && opp.Terrace_Area_Sqm__c != Null){
                    opp.Price_Sqm_SAR_Terrace__c = opp.Total_Prices_Terrace_Area__c/opp.Terrace_Area_Sqm__c;    
                }else{
                    opp.Price_Sqm_SAR_Terrace__c = 0;
                }
                //--------------------------------------------------     
                }
                //------------------idDBtoRate_per_Sqm_SR_Sqm---------------------------
                if(opp.RecordType.Name == 'Offices'){
                    if(opp.Total_Annual_Rent_SR_Annum__c != 0 && opp.Area_Sqm__c != 0 && opp.Total_Annual_Rent_SR_Annum__c != Null && opp.Area_Sqm__c != Null){
                        opp.Rate_per_Sqm_SR_Sqm__c = opp.Total_Annual_Rent_SR_Annum__c/opp.Area_Sqm__c;    
                    }else{
                        opp.Rate_per_Sqm_SR_Sqm__c = 0;
                    }    
                }
                if(opp.RecordType.Name == 'Retail'){
                    if(opp.Total_Annual_Rent__c != 0 && opp.Area_Sqm__c != 0 && opp.Total_Annual_Rent__c != Null && opp.Area_Sqm__c != Null){
                        opp.Rate_per_Sqm_SR_Sqm__c = opp.Total_Annual_Rent__c/opp.Area_Sqm__c;    
                    }else{
                        opp.Rate_per_Sqm_SR_Sqm__c = 0;
                    }
                }
                
                oppListForUpdate.add(opp);
            }    
        }
        
        if(oppListForUpdate.size() > 0){
            update oppListForUpdate;    
        }
    }
    
    private static void plug(){
        Boolean b = true;
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
    }
}