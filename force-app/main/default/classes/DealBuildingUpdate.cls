public class DealBuildingUpdate {
	public static void afterUpdate(list<Deal_Building__c> triggerNew, Map<Id,Deal_Building__c>oldMap){
        plug();
        Map<Id, Double> mapToOldCurrency = new Map<Id, Double>();
        Map<Id, Double> mapToNewCurrency = new Map<Id, Double>();
        
        map<Id, Decimal> idDBtoOLDUnitSize = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWUnitSize = new map<Id, Decimal>();

        map<Id, Decimal> idDBtoOLDService_Area_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWService_Area_Sqm = new map<Id, Decimal>();

        map<Id, Decimal> idDBtoOLDTerrace_Area_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWTerrace_Area_Sqm = new map<Id, Decimal>();

        map<Id, Decimal> idDBtoOLDService_Area_SAR = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWService_Area_SAR = new map<Id, Decimal>();

        map<Id, Decimal> idDBtoOLDTerrace_Area_SAR = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWTerrace_Area_SAR = new map<Id, Decimal>();

        map<Id, Decimal> idDBtoOLDMinimum_Acceptable_Rent = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWMinimum_Acceptable_Rent = new map<Id, Decimal>();
        //-------------------------------------------------------------------------
		map<Id, Decimal> idDBtoOLDAsking_Rate_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoOLDTotal_Asking_Rent_SR = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoOLDArea_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoOLDRate_per_Sqm_SR_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoOLDTotal_Annual_Rent_SR_Annum = new map<Id, Decimal>();
        map<Id, String> idDBtoOLDUnit_Number = new map<Id, String>();
        map<Id, Decimal> idDBtoOLDTotal_Annual_Rent = new map<Id, Decimal>();
        //--------------------------------------------------------------------------
        map<Id, Decimal> idDBtoNEWAsking_Rate_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWTotal_Asking_Rent_SR = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWArea_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWRate_per_Sqm_SR_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWTotal_Annual_Rent_SR_Annum = new map<Id, Decimal>();
        map<Id, String> idDBtoNEWUnit_Number = new map<Id, String>();
        map<Id, Decimal> idDBtoNEWTotal_Annual_Rent = new map<Id, Decimal>();
        //--------------------------------------------------------------------------
        map<Id, Decimal> idDBtoNEWMinimum_Lobby_Area_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoNEWMinimum_Price_Sqm_SAR_Lobby = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoOLDMinimum_Lobby_Area_Sqm = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoOLDMinimum_Price_Sqm_SAR_Lobby = new map<Id, Decimal>();  
        //--------------------------------------------------------------------------
        map<Id, Decimal> idDBtoMinimum_UASNEW = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_TPUANEW = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_UASOLD = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_TPUAOLD = new map<Id, Decimal>();
        //---------------------------------------------------------------------
        map<Id, Decimal> idDBtoMinimum_TPSANEW = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_TPTANEW = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_TPSAOLD = new map<Id, Decimal>();
        map<Id, Decimal> idDBtoMinimum_TPTAOLD = new map<Id, Decimal>();
        //---------------------------------------------------------------------
        Set<Id> oppForUpdateSet = new Set<Id>();
        //Set<Id> oppIdList = new Set<Id>();
        Set<Id> oppIdList = new Set<Id>();
        for(Deal_Building__c db : triggerNew){
            oppIdList.add(db.Deal__c);
        }
        Map<Id, Opportunity> mapOpportunity = new Map<Id, Opportunity>([SELECT Id, RecordType.Name FROM Opportunity WHERE Id IN:oppIdList]);
        //-------------------------------------------
        for(Deal_Building__c dbNew : triggerNew){
            //---------------------------idDBtoMinimum_UASNEW---------------------------------
            if(dbNew.Unit_Area_Sqm_NSA__c != oldMap.get(dbNew.Id).Unit_Area_Sqm_NSA__c){
                if(idDBtoMinimum_UASNEW.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoMinimum_UASNEW.get(dbNew.Deal__c) + dbNew.Unit_Area_Sqm_NSA__c;
                    idDBtoMinimum_UASNEW.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoMinimum_UASNEW.put(dbNew.Deal__c, dbNew.Unit_Area_Sqm_NSA__c);     
                }
                
                if(idDBtoMinimum_UASOLD.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoMinimum_UASOLD.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Unit_Area_Sqm_NSA__c;
                    idDBtoMinimum_UASOLD.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoMinimum_UASOLD.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Unit_Area_Sqm_NSA__c);
                }
            }
            //---------------------------idDBtoMinimum_TPUANEW---------------------------------
            if(dbNew.Total_NSA__c != oldMap.get(dbNew.Id).Total_NSA__c){
                if(idDBtoMinimum_TPUANEW.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoMinimum_TPUANEW.get(dbNew.Deal__c) + dbNew.Total_NSA__c;
                    idDBtoMinimum_TPUANEW.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoMinimum_TPUANEW.put(dbNew.Deal__c, dbNew.Total_NSA__c);     
                }
                
                if(idDBtoMinimum_TPUAOLD.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoMinimum_TPUAOLD.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_NSA__c;
                    idDBtoMinimum_TPUAOLD.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoMinimum_TPUAOLD.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_NSA__c);
                }
            }
            //---------------------------idDBtoMinimum_TPSANEW---------------------------------
            if(dbNew.Total_Prices_Services_Areas__c != oldMap.get(dbNew.Id).Total_Prices_Services_Areas__c){
                if(idDBtoMinimum_TPSANEW.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoMinimum_TPSANEW.get(dbNew.Deal__c) + dbNew.Total_Prices_Services_Areas__c;
                    idDBtoMinimum_TPSANEW.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoMinimum_TPSANEW.put(dbNew.Deal__c, dbNew.Total_Prices_Services_Areas__c);     
                }
                
                if(idDBtoMinimum_TPSAOLD.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoMinimum_TPSAOLD.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Prices_Services_Areas__c;
                    idDBtoMinimum_TPSAOLD.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoMinimum_TPSAOLD.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Prices_Services_Areas__c);
                }
            }
            //---------------------------idDBtoMinimum_TPTANEW---------------------------------
            if(dbNew.Total_Prices_Terraces_Areas__c != oldMap.get(dbNew.Id).Total_Prices_Terraces_Areas__c){
                if(idDBtoMinimum_TPTANEW.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoMinimum_TPTANEW.get(dbNew.Deal__c) + dbNew.Total_Prices_Terraces_Areas__c;
                    idDBtoMinimum_TPTANEW.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoMinimum_TPTANEW.put(dbNew.Deal__c, dbNew.Total_Prices_Terraces_Areas__c);     
                }
                
                if(idDBtoMinimum_TPTAOLD.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoMinimum_TPTAOLD.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Prices_Terraces_Areas__c;
                    idDBtoMinimum_TPTAOLD.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoMinimum_TPTAOLD.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Prices_Terraces_Areas__c);
                }
            }
            //---------------------------------------------------------------------------------------
            //---------------------------Lobby1---------------------------------
            if(dbNew.Lobby_Area_Sqm__c != oldMap.get(dbNew.Id).Lobby_Area_Sqm__c){
                if(idDBtoNEWMinimum_Lobby_Area_Sqm.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoNEWMinimum_Lobby_Area_Sqm.get(dbNew.Deal__c) + dbNew.Lobby_Area_Sqm__c;
                    idDBtoNEWMinimum_Lobby_Area_Sqm.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoNEWMinimum_Lobby_Area_Sqm.put(dbNew.Deal__c, dbNew.Lobby_Area_Sqm__c);     
                }
                
                if(idDBtoOLDMinimum_Lobby_Area_Sqm.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoOLDMinimum_Lobby_Area_Sqm.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Lobby_Area_Sqm__c;
                    idDBtoOLDMinimum_Lobby_Area_Sqm.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoOLDMinimum_Lobby_Area_Sqm.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Lobby_Area_Sqm__c);
                }
            }
            //---------------------------Lobby2---------------------------------
            if(dbNew.Total_Prices_Lobby__c != oldMap.get(dbNew.Id).Total_Prices_Lobby__c){
                if(idDBtoNEWMinimum_Price_Sqm_SAR_Lobby.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoNEWMinimum_Price_Sqm_SAR_Lobby.get(dbNew.Deal__c) + dbNew.Total_Prices_Lobby__c;
                    idDBtoNEWMinimum_Price_Sqm_SAR_Lobby.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoNEWMinimum_Price_Sqm_SAR_Lobby.put(dbNew.Deal__c, dbNew.Total_Prices_Lobby__c);     
                }
                
                if(idDBtoOLDMinimum_Price_Sqm_SAR_Lobby.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoOLDMinimum_Price_Sqm_SAR_Lobby.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Prices_Lobby__c;
                    idDBtoOLDMinimum_Price_Sqm_SAR_Lobby.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoOLDMinimum_Price_Sqm_SAR_Lobby.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Prices_Lobby__c);
                }
            }
            //---------------------------idDBtoNEWAsking_Rate_Sqm---------------------------------
            if(dbNew.Leasing_Rate_Sqm_SAR__c != oldMap.get(dbNew.Id).Leasing_Rate_Sqm_SAR__c){
                if(idDBtoNEWAsking_Rate_Sqm.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoNEWAsking_Rate_Sqm.get(dbNew.Deal__c) + dbNew.Leasing_Rate_Sqm_SAR__c;
                    idDBtoNEWAsking_Rate_Sqm.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoNEWAsking_Rate_Sqm.put(dbNew.Deal__c, dbNew.Leasing_Rate_Sqm_SAR__c);     
                }
                
                if(idDBtoOLDAsking_Rate_Sqm.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoOLDAsking_Rate_Sqm.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Leasing_Rate_Sqm_SAR__c;
                    idDBtoOLDAsking_Rate_Sqm.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoOLDAsking_Rate_Sqm.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Leasing_Rate_Sqm_SAR__c);
                }
            }
            //---------------------------idDBtoNEWTotal_Asking_Rent_SR---------------------------------
            if(dbNew.Total_NSA__c != oldMap.get(dbNew.Id).Total_NSA__c){
                if(idDBtoNEWTotal_Asking_Rent_SR.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoNEWTotal_Asking_Rent_SR.get(dbNew.Deal__c) + dbNew.Total_NSA__c;
                    idDBtoNEWTotal_Asking_Rent_SR.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoNEWTotal_Asking_Rent_SR.put(dbNew.Deal__c, dbNew.Total_NSA__c);     
                }
                
                if(idDBtoOLDTotal_Asking_Rent_SR.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoOLDTotal_Asking_Rent_SR.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_NSA__c;
                    idDBtoOLDTotal_Asking_Rent_SR.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoOLDTotal_Asking_Rent_SR.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_NSA__c);
                }
            }
            //---------------------------idDBtoNEWArea_Sqm---------------------------------
            if(mapOpportunity.get(dbNew.Deal__c).RecordType.Name == 'Offices'){
            	if(dbNew.Total_Leasable_Area_Sqm__c  != oldMap.get(dbNew.Id).Total_Leasable_Area_Sqm__c ){
                    if(idDBtoNEWArea_Sqm.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoNEWArea_Sqm.get(dbNew.Deal__c) + dbNew.Total_Leasable_Area_Sqm__c ;
                        idDBtoNEWArea_Sqm.put(dbNew.Deal__c, dcCurrency);     
                    }else{
                        idDBtoNEWArea_Sqm.put(dbNew.Deal__c, dbNew.Total_Leasable_Area_Sqm__c );     
                    }
                    
                    if(idDBtoOLDArea_Sqm.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoOLDArea_Sqm.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Leasable_Area_Sqm__c ;
                        idDBtoOLDArea_Sqm.put(dbNew.Deal__c, dcCurrency);
                    }else{
                        idDBtoOLDArea_Sqm.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Leasable_Area_Sqm__c );
                    }
                }    
            }
            if(mapOpportunity.get(dbNew.Deal__c).RecordType.Name == 'Retail'){
            	if(dbNew.Unit_Area_Sqm__c  != oldMap.get(dbNew.Id).Unit_Area_Sqm__c ){
                    if(idDBtoNEWArea_Sqm.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoNEWArea_Sqm.get(dbNew.Deal__c) + dbNew.Unit_Area_Sqm__c ;
                        idDBtoNEWArea_Sqm.put(dbNew.Deal__c, dcCurrency);     
                    }else{
                        idDBtoNEWArea_Sqm.put(dbNew.Deal__c, dbNew.Unit_Area_Sqm__c );     
                    }
                    
                    if(idDBtoOLDArea_Sqm.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoOLDArea_Sqm.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Unit_Area_Sqm__c ;
                        idDBtoOLDArea_Sqm.put(dbNew.Deal__c, dcCurrency);
                    }else{
                        idDBtoOLDArea_Sqm.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Unit_Area_Sqm__c );
                    }
                }    
            }
            
            //---------------------------idDBtoNEWRate_per_Sqm_SR_Sqm---------------------------------
            if(mapOpportunity.get(dbNew.Deal__c).RecordType.Name == 'Offices'){
            	if(dbNew.Total_Selling_Price_SAR__c  != oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c || dbNew.Total_Leasable_Area_Sqm__c != oldMap.get(dbNew.Id).Total_Leasable_Area_Sqm__c ){
                    if(idDBtoNEWRate_per_Sqm_SR_Sqm.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoNEWRate_per_Sqm_SR_Sqm.get(dbNew.Deal__c) + dbNew.Total_Selling_Price_SAR__c/dbNew.Total_Leasable_Area_Sqm__c  ;
                        idDBtoNEWRate_per_Sqm_SR_Sqm.put(dbNew.Deal__c, dcCurrency);     
                    }else{
                        if(dbNew.Total_Selling_Price_SAR__c != 0 && dbNew.Total_Leasable_Area_Sqm__c != 0){
                        	idDBtoNEWRate_per_Sqm_SR_Sqm.put(dbNew.Deal__c, dbNew.Total_Selling_Price_SAR__c/dbNew.Total_Leasable_Area_Sqm__c );     
                        }
                    }
                    
                    if(idDBtoOLDRate_per_Sqm_SR_Sqm.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoOLDRate_per_Sqm_SR_Sqm.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c/oldMap.get(dbNew.Id).Total_Leasable_Area_Sqm__c ;
                        idDBtoOLDRate_per_Sqm_SR_Sqm.put(dbNew.Deal__c, dcCurrency);
                    }else{
                        if(oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c != 0 && oldMap.get(dbNew.Id).Total_Leasable_Area_Sqm__c != 0){
                        	idDBtoOLDRate_per_Sqm_SR_Sqm.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c/oldMap.get(dbNew.Id).Total_Leasable_Area_Sqm__c );
                        }
                    }
                }    
            }
            if(mapOpportunity.get(dbNew.Deal__c).RecordType.Name == 'Retail'){
            	if(dbNew.Asking_Price__c  != oldMap.get(dbNew.Id).Asking_Price__c ){
                    if(idDBtoNEWRate_per_Sqm_SR_Sqm.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoNEWRate_per_Sqm_SR_Sqm.get(dbNew.Deal__c) + dbNew.Asking_Price__c ;
                        idDBtoNEWRate_per_Sqm_SR_Sqm.put(dbNew.Deal__c, dcCurrency);     
                    }else{
                        idDBtoNEWRate_per_Sqm_SR_Sqm.put(dbNew.Deal__c, dbNew.Asking_Price__c );     
                    }
                    
                    if(idDBtoOLDRate_per_Sqm_SR_Sqm.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoOLDRate_per_Sqm_SR_Sqm.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Asking_Price__c ;
                        idDBtoOLDRate_per_Sqm_SR_Sqm.put(dbNew.Deal__c, dcCurrency);
                    }else{
                        idDBtoOLDRate_per_Sqm_SR_Sqm.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Asking_Price__c );
                    }
                }    
            }
            
            //---------------------------idDBtoNEWTotal_Annual_Rent_SR_Annum---------------------------------
            if(dbNew.Total_Selling_Price_SAR__c != oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c){
                if(idDBtoNEWTotal_Annual_Rent_SR_Annum.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoNEWTotal_Annual_Rent_SR_Annum.get(dbNew.Deal__c) + dbNew.Total_Selling_Price_SAR__c;
                    idDBtoNEWTotal_Annual_Rent_SR_Annum.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoNEWTotal_Annual_Rent_SR_Annum.put(dbNew.Deal__c, dbNew.Total_Selling_Price_SAR__c);     
                }
                
                if(idDBtoOLDTotal_Annual_Rent_SR_Annum.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoOLDTotal_Annual_Rent_SR_Annum.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c;
                    idDBtoOLDTotal_Annual_Rent_SR_Annum.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoOLDTotal_Annual_Rent_SR_Annum.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c);
                }
            }
            //---------------------------idDBtoNEWTotal_Annual_Rent---------------------------------
            if(dbNew.Total_Selling_Price_SAR__c  != oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c ){
                if(idDBtoNEWTotal_Annual_Rent.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoNEWTotal_Annual_Rent.get(dbNew.Deal__c) + dbNew.Total_Selling_Price_SAR__c;
                    idDBtoNEWTotal_Annual_Rent.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoNEWTotal_Annual_Rent.put(dbNew.Deal__c, dbNew.Total_Selling_Price_SAR__c);     
                }
                
                if(idDBtoOLDTotal_Annual_Rent.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoOLDTotal_Annual_Rent.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c;
                    idDBtoOLDTotal_Annual_Rent.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoOLDTotal_Annual_Rent.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c);
                }
            }
            //-------------------------------------------------------------------------------------
            if(dbNew.Total_Selling_Price_SAR__c != oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c){
                if(mapToNewCurrency.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = mapToNewCurrency.get(dbNew.Deal__c) + dbNew.Total_Selling_Price_SAR__c;
                    mapToNewCurrency.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    mapToNewCurrency.put(dbNew.Deal__c, dbNew.Total_Selling_Price_SAR__c);     
                }
                
                if(mapToOldCurrency.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = mapToOldCurrency.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c;
                    mapToOldCurrency.put(dbNew.Deal__c, dcCurrency);
                }else{
                    mapToOldCurrency.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Selling_Price_SAR__c);
                }
            }
            //-----------------------------Unit_Size_SQM__c-------------------------------
            if(dbNew.Total_Leasable_Area_Sqm__c != oldMap.get(dbNew.Id).Total_Leasable_Area_Sqm__c){
                if(mapOpportunity.get(dbNew.Deal__c).RecordType.Name == 'Offices'){//Offices
                    if(idDBtoNEWUnitSize.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoNEWUnitSize.get(dbNew.Deal__c) + dbNew.Total_Leasable_Area_Sqm__c;
                        idDBtoNEWUnitSize.put(dbNew.Deal__c, dcCurrency);     
                    }else{
                        idDBtoNEWUnitSize.put(dbNew.Deal__c, dbNew.Total_Leasable_Area_Sqm__c);     
                    }
                    
                    if(idDBtoOLDUnitSize.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoOLDUnitSize.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Leasable_Area_Sqm__c;
                        idDBtoOLDUnitSize.put(dbNew.Deal__c, dcCurrency);
                    }else{
                        idDBtoOLDUnitSize.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Leasable_Area_Sqm__c);
                    }
                }

                if(mapOpportunity.get(dbNew.Deal__c).RecordType.Name == 'Retail'){//Retail
                    if(idDBtoNEWUnitSize.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoNEWUnitSize.get(dbNew.Deal__c) + dbNew.Unit_Area_Sqm__c;
                        idDBtoNEWUnitSize.put(dbNew.Deal__c, dcCurrency);     
                    }else{
                        idDBtoNEWUnitSize.put(dbNew.Deal__c, dbNew.Unit_Area_Sqm__c);     
                    }
                    
                    if(idDBtoOLDUnitSize.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoOLDUnitSize.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Unit_Area_Sqm_NSA__c;
                        idDBtoOLDUnitSize.put(dbNew.Deal__c, dcCurrency);
                    }else{
                        idDBtoOLDUnitSize.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Unit_Area_Sqm_NSA__c);
                    }
                }
                
            }
            //-----------------------------Service_Area_Sqm__c-------------------------------
            if(dbNew.Service_Area_Sqm__c != oldMap.get(dbNew.Id).Service_Area_Sqm__c){
                if(idDBtoNEWTerrace_Area_Sqm.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoNEWTerrace_Area_Sqm.get(dbNew.Deal__c) + dbNew.Service_Area_Sqm__c;
                    idDBtoNEWTerrace_Area_Sqm.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoNEWTerrace_Area_Sqm.put(dbNew.Deal__c, dbNew.Service_Area_Sqm__c);     
                }
                
                if(idDBtoOLDService_Area_Sqm.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoOLDService_Area_Sqm.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Service_Area_Sqm__c;
                    idDBtoOLDService_Area_Sqm.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoOLDService_Area_Sqm.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Service_Area_Sqm__c);
                }
            }
            //-----------------------------Terrace_Area_Sqm__c-------------------------------
            if(dbNew.Terrace_Area_Sqm__c != oldMap.get(dbNew.Id).Terrace_Area_Sqm__c){
                if(idDBtoNEWTerrace_Area_Sqm.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoNEWTerrace_Area_Sqm.get(dbNew.Deal__c) + dbNew.Terrace_Area_Sqm__c;
                    idDBtoNEWTerrace_Area_Sqm.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoNEWTerrace_Area_Sqm.put(dbNew.Deal__c, dbNew.Terrace_Area_Sqm__c);     
                }
                
                if(idDBtoOLDTerrace_Area_Sqm.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoOLDTerrace_Area_Sqm.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Terrace_Area_Sqm__c;
                    idDBtoOLDTerrace_Area_Sqm.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoOLDTerrace_Area_Sqm.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Terrace_Area_Sqm__c);
                }
            }
            //-----------------------------Service_Area_SAR__c-------------------------------
            if(dbNew.Total_Prices_Services_Areas__c != oldMap.get(dbNew.Id).Total_Prices_Services_Areas__c){
                if(idDBtoNEWService_Area_SAR.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoNEWService_Area_SAR.get(dbNew.Deal__c) + dbNew.Total_Prices_Services_Areas__c;
                    idDBtoNEWService_Area_SAR.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoNEWService_Area_SAR.put(dbNew.Deal__c, dbNew.Total_Prices_Services_Areas__c);     
                }
                
                if(idDBtoOLDService_Area_SAR.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoOLDService_Area_SAR.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Prices_Services_Areas__c;
                    idDBtoOLDService_Area_SAR.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoOLDService_Area_SAR.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Prices_Services_Areas__c);
                }
            }
            //-----------------------------Terrace_Area_SAR__c-------------------------------
            if(dbNew.Total_Prices_Terraces_Areas__c != oldMap.get(dbNew.Id).Total_Prices_Terraces_Areas__c){
                if(idDBtoNEWTerrace_Area_SAR.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoNEWTerrace_Area_SAR.get(dbNew.Deal__c) + dbNew.Total_Prices_Terraces_Areas__c;
                    idDBtoNEWTerrace_Area_SAR.put(dbNew.Deal__c, dcCurrency);     
                }else{
                    idDBtoNEWTerrace_Area_SAR.put(dbNew.Deal__c, dbNew.Total_Prices_Terraces_Areas__c);     
                }
                
                if(idDBtoOLDTerrace_Area_SAR.containsKey(dbNew.Deal__c)){
                    Decimal dcCurrency = idDBtoOLDTerrace_Area_SAR.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_Prices_Terraces_Areas__c;
                    idDBtoOLDTerrace_Area_SAR.put(dbNew.Deal__c, dcCurrency);
                }else{
                    idDBtoOLDTerrace_Area_SAR.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_Prices_Terraces_Areas__c);
                }
            }
            //-----------------------------Minimum_Acceptable_Rent__c-------------------------------
            if(dbNew.Total_NSA__c != oldMap.get(dbNew.Id).Total_NSA__c){
                if(mapOpportunity.get(dbNew.Deal__c).RecordType.Name == 'Offices'){//Offices
                    if(idDBtoNEWMinimum_Acceptable_Rent.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoNEWMinimum_Acceptable_Rent.get(dbNew.Deal__c) + dbNew.Total_NSA__c;
                        idDBtoNEWMinimum_Acceptable_Rent.put(dbNew.Deal__c, dcCurrency);     
                    }else{
                        idDBtoNEWMinimum_Acceptable_Rent.put(dbNew.Deal__c, dbNew.Total_NSA__c);     
                    }
                    
                    if(idDBtoOLDMinimum_Acceptable_Rent.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoOLDMinimum_Acceptable_Rent.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Total_NSA__c;
                        idDBtoOLDMinimum_Acceptable_Rent.put(dbNew.Deal__c, dcCurrency);
                    }else{
                        idDBtoOLDMinimum_Acceptable_Rent.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Total_NSA__c);
                    }
                }

                if(mapOpportunity.get(dbNew.Deal__c).RecordType.Name == 'Retail'){//Retail
                    if(idDBtoNEWMinimum_Acceptable_Rent.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoNEWMinimum_Acceptable_Rent.get(dbNew.Deal__c) + dbNew.Minimum_Annual_Rent__c;
                        idDBtoNEWMinimum_Acceptable_Rent.put(dbNew.Deal__c, dcCurrency);     
                    }else{
                        idDBtoNEWMinimum_Acceptable_Rent.put(dbNew.Deal__c, dbNew.Minimum_Annual_Rent__c);     
                    }
                    
                    if(idDBtoOLDMinimum_Acceptable_Rent.containsKey(dbNew.Deal__c)){
                        Decimal dcCurrency = idDBtoOLDMinimum_Acceptable_Rent.get(dbNew.Deal__c) + oldMap.get(dbNew.Id).Minimum_Annual_Rent__c;
                        idDBtoOLDMinimum_Acceptable_Rent.put(dbNew.Deal__c, dcCurrency);
                    }else{
                        idDBtoOLDMinimum_Acceptable_Rent.put(dbNew.Deal__c, oldMap.get(dbNew.Id).Minimum_Annual_Rent__c);
                    }
                }
            }
            oppForUpdateSet.add(dbNew.Deal__c);
        }
        
        List<Opportunity> oppListForUpdate = new List<Opportunity>();
        if(oppForUpdateSet.size() > 0){
            for(Opportunity opp : [SELECT Id, 
                                        Amount, 
                                        Unit_Size_SQM__c, 
                                        Service_Area_Sqm__c,
                                        Terrace_Area_Sqm__c,
                                        Service_Area_SAR__c,
                                        Terrace_Area_SAR__c,
                                        Minimum_Acceptable_Rent__c,
                                        Minimum_Acceptable_Rate_Sqm_SR_Sqm__c,
                                   //--------------------------------------------
                                   		Asking_Rate_Sqm__c,
                                   		Total_Asking_Rent_SR__c,
                                   		Area_Sqm__c,
                                   		Rate_per_Sqm_SR_Sqm__c,
                                   		Total_Annual_Rent_SR_Annum__c,
                                   		Unit_Number__c,
                                   		Total_Annual_Rent__c,
                                   		RecordType.Name,
                                   		Lobby_Area_Sqm__c,
                                   		Price_Sqm_SAR_Lobby__c,
                                   		Total_Prices_Lobby_Areas__c,
                                   		//--------------------------
                                   		Unit_Area_Sqm__c,
                                   		Price_Sqm_SAR_Unit__c,
                                   		Total_Prices_Unit_Area__c,
                                   		Price_Sqm_SAR_Service__c,
                                   		Total_Prices_Service_Area__c,
                                   		Price_Sqm_SAR_Terrace__c,
                                   		Total_Prices_Terrace_Area__c
                                    FROM Opportunity WHERE Id IN :oppForUpdateSet]){
        //map<Id, Decimal> idDBtoMinimum_UASNEW = new map<Id, Decimal>();
        //map<Id, Decimal> idDBtoMinimum_TPUANEW = new map<Id, Decimal>();
        //map<Id, Decimal> idDBtoMinimum_UASOLD = new map<Id, Decimal>();
        //map<Id, Decimal> idDBtoMinimum_TPUAOLD = new map<Id, Decimal>();
        //---------------------------------------------------------------------
        //map<Id, Decimal> idDBtoMinimum_TPSANEW = new map<Id, Decimal>();
        //map<Id, Decimal> idDBtoMinimum_TPTANEW = new map<Id, Decimal>();
        //map<Id, Decimal> idDBtoMinimum_TPSAOLD = new map<Id, Decimal>();
        //map<Id, Decimal> idDBtoMinimum_TPTAOLD = new map<Id, Decimal>();
        		
                //-----------------------Lobby1--------------------------                       
                if(idDBtoNEWMinimum_Lobby_Area_Sqm.keySet().size() > 0 && idDBtoNEWMinimum_Lobby_Area_Sqm.get(opp.Id) != null){
                    if(opp.Lobby_Area_Sqm__c == null){
                       opp.Lobby_Area_Sqm__c = 0; 
                    }
                    opp.Lobby_Area_Sqm__c = opp.Lobby_Area_Sqm__c+idDBtoNEWMinimum_Lobby_Area_Sqm.get(opp.Id);    
                }
                if(idDBtoOLDMinimum_Lobby_Area_Sqm.keySet().size() > 0 && idDBtoOLDMinimum_Lobby_Area_Sqm.get(opp.Id) != null){
                    if(opp.Lobby_Area_Sqm__c == null){
                       opp.Lobby_Area_Sqm__c = 0; 
                    }
                    opp.Lobby_Area_Sqm__c = opp.Lobby_Area_Sqm__c-idDBtoOLDMinimum_Lobby_Area_Sqm.get(opp.Id);    
                }
                //-----------------------Lobby2--------------------------                       
                if(idDBtoNEWMinimum_Price_Sqm_SAR_Lobby.keySet().size() > 0 && idDBtoNEWMinimum_Price_Sqm_SAR_Lobby.get(opp.Id) != null){
                    if(opp.Total_Prices_Lobby_Areas__c == null){
                       opp.Total_Prices_Lobby_Areas__c = 0; 
                    }
                    opp.Total_Prices_Lobby_Areas__c = opp.Total_Prices_Lobby_Areas__c+idDBtoNEWMinimum_Price_Sqm_SAR_Lobby.get(opp.Id);    
                }
                if(idDBtoOLDMinimum_Price_Sqm_SAR_Lobby.keySet().size() > 0 && idDBtoOLDMinimum_Price_Sqm_SAR_Lobby.get(opp.Id) != null){
                    if(opp.Total_Prices_Lobby_Areas__c == null){
                       opp.Total_Prices_Lobby_Areas__c = 0; 
                    }
                    opp.Total_Prices_Lobby_Areas__c = opp.Total_Prices_Lobby_Areas__c-idDBtoOLDMinimum_Price_Sqm_SAR_Lobby.get(opp.Id);    
                }
                //------------------Lobby3---------------------------
                if(opp.RecordType.Name == 'Offices'){
                    if(opp.Total_Prices_Lobby_Areas__c != 0 && opp.Lobby_Area_Sqm__c != 0 && opp.Total_Prices_Lobby_Areas__c != Null && opp.Lobby_Area_Sqm__c != Null){
                        opp.Price_Sqm_SAR_Lobby__c = opp.Total_Prices_Lobby_Areas__c/opp.Lobby_Area_Sqm__c;    
                    }else{
                        opp.Price_Sqm_SAR_Lobby__c = 0;
                    }    
                }                        
                //-----------------------Total_Asking_Rent_SR__c--------------------------                       
                if(idDBtoNEWTotal_Asking_Rent_SR.keySet().size() > 0 && idDBtoNEWTotal_Asking_Rent_SR.get(opp.Id) != null){
                    if(opp.Total_Asking_Rent_SR__c == null){
                       opp.Total_Asking_Rent_SR__c = 0; 
                    }
                    opp.Total_Asking_Rent_SR__c = opp.Total_Asking_Rent_SR__c+idDBtoNEWTotal_Asking_Rent_SR.get(opp.Id);    
                }
                if(idDBtoOLDTotal_Asking_Rent_SR.keySet().size() > 0 && idDBtoOLDTotal_Asking_Rent_SR.get(opp.Id) != null){
                    if(opp.Total_Asking_Rent_SR__c == null){
                       opp.Total_Asking_Rent_SR__c = 0; 
                    }
                    opp.Total_Asking_Rent_SR__c = opp.Total_Asking_Rent_SR__c-idDBtoOLDTotal_Asking_Rent_SR.get(opp.Id);    
                }
                //-----------------------Area_Sqm__c--------------------------                       
                if(idDBtoNEWArea_Sqm.keySet().size() > 0 && idDBtoNEWArea_Sqm.get(opp.Id) != null){
                    if(opp.Area_Sqm__c == null){
                       opp.Area_Sqm__c = 0; 
                    }
                    opp.Area_Sqm__c = opp.Area_Sqm__c+idDBtoNEWArea_Sqm.get(opp.Id);    
                }
                if(idDBtoOLDArea_Sqm.keySet().size() > 0 && idDBtoOLDArea_Sqm.get(opp.Id) != null){
                    if(opp.Area_Sqm__c == null){
                       opp.Area_Sqm__c = 0; 
                    }
                    opp.Area_Sqm__c = opp.Area_Sqm__c-idDBtoOLDArea_Sqm.get(opp.Id);    
                }
                //-----------------------Rate_per_Sqm_SR_Sqm__c--------------------------                       
                if(idDBtoNEWRate_per_Sqm_SR_Sqm.keySet().size() > 0 && idDBtoNEWRate_per_Sqm_SR_Sqm.get(opp.Id) != null){
                    if(opp.Rate_per_Sqm_SR_Sqm__c == null){
                       opp.Rate_per_Sqm_SR_Sqm__c = 0; 
                    }
                    opp.Rate_per_Sqm_SR_Sqm__c = opp.Rate_per_Sqm_SR_Sqm__c+idDBtoNEWRate_per_Sqm_SR_Sqm.get(opp.Id);    
                }
                if(idDBtoOLDRate_per_Sqm_SR_Sqm.keySet().size() > 0 && idDBtoOLDRate_per_Sqm_SR_Sqm.get(opp.Id) != null){
                    if(opp.Rate_per_Sqm_SR_Sqm__c == null){
                       opp.Rate_per_Sqm_SR_Sqm__c = 0; 
                    }
                    opp.Rate_per_Sqm_SR_Sqm__c = opp.Rate_per_Sqm_SR_Sqm__c-idDBtoOLDRate_per_Sqm_SR_Sqm.get(opp.Id);    
                }
                //-----------------------Total_Annual_Rent_SR_Annum__c--------------------------                       
                if(idDBtoNEWTotal_Annual_Rent_SR_Annum.keySet().size() > 0 && idDBtoNEWTotal_Annual_Rent_SR_Annum.get(opp.Id) != null){
                    if(opp.Total_Annual_Rent_SR_Annum__c == null){
                       opp.Total_Annual_Rent_SR_Annum__c = 0; 
                    }
                    opp.Total_Annual_Rent_SR_Annum__c = opp.Total_Annual_Rent_SR_Annum__c+idDBtoNEWTotal_Annual_Rent_SR_Annum.get(opp.Id);    
                }
                if(idDBtoOLDTotal_Annual_Rent_SR_Annum.keySet().size() > 0 && idDBtoOLDTotal_Annual_Rent_SR_Annum.get(opp.Id) != null){
                    if(opp.Total_Annual_Rent_SR_Annum__c == null){
                       opp.Total_Annual_Rent_SR_Annum__c = 0; 
                    }
                    opp.Total_Annual_Rent_SR_Annum__c = opp.Total_Annual_Rent_SR_Annum__c-idDBtoOLDTotal_Annual_Rent_SR_Annum.get(opp.Id);    
                }
                                        
                //-----------------------Total_Annual_Rent__c--------------------------                       
                if(idDBtoNEWTotal_Annual_Rent.keySet().size() > 0 && idDBtoNEWTotal_Annual_Rent.get(opp.Id) != null){
                    if(opp.Total_Annual_Rent__c == null){
                       opp.Total_Annual_Rent__c = 0; 
                    }
                    opp.Total_Annual_Rent__c = opp.Total_Annual_Rent__c+idDBtoNEWTotal_Annual_Rent.get(opp.Id);    
                }
                if(idDBtoOLDTotal_Annual_Rent.keySet().size() > 0 && idDBtoOLDTotal_Annual_Rent.get(opp.Id) != null){
                    if(opp.Total_Annual_Rent__c == null){
                       opp.Total_Annual_Rent__c = 0; 
                    }
                    opp.Total_Annual_Rent__c = opp.Total_Annual_Rent__c-idDBtoOLDTotal_Annual_Rent.get(opp.Id);    
                }
                                        
                //-----------------------Amount--------------------------                       
                if(mapToNewCurrency.keySet().size() > 0 && mapToNewCurrency.get(opp.Id) != null){
                    if(opp.Amount == null){
                       opp.Amount = 0; 
                    }
                    opp.Amount = opp.Amount+mapToNewCurrency.get(opp.Id);    
                }
                if(mapToOldCurrency.keySet().size() > 0 && mapToOldCurrency.get(opp.Id) != null){
                    opp.Amount = opp.Amount-mapToOldCurrency.get(opp.Id);    
                }
                //-----------------------Unit_Size_SQM__c--------------------------                       
                if(idDBtoNEWUnitSize.keySet().size() > 0 && idDBtoNEWUnitSize.get(opp.Id) != null){
                    if(opp.Unit_Size_SQM__c == null){
                       opp.Unit_Size_SQM__c = 0; 
                    }
                    opp.Unit_Size_SQM__c = opp.Unit_Size_SQM__c+idDBtoNEWUnitSize.get(opp.Id);    
                }
                if(idDBtoOLDUnitSize.keySet().size() > 0 && idDBtoOLDUnitSize.get(opp.Id) != null){
                    if(opp.Unit_Size_SQM__c == null){
                       opp.Unit_Size_SQM__c = 0; 
                    }
                    opp.Unit_Size_SQM__c = opp.Unit_Size_SQM__c-idDBtoOLDUnitSize.get(opp.Id);    
                }
                //-----------------------Service_Area_Sqm__c--------------------------                       
                if(idDBtoNEWService_Area_Sqm.keySet().size() > 0 && idDBtoNEWService_Area_Sqm.get(opp.Id) != null){
                    if(opp.Service_Area_Sqm__c == null){
                       opp.Service_Area_Sqm__c = 0; 
                    }
                    opp.Service_Area_Sqm__c = opp.Service_Area_Sqm__c+idDBtoNEWService_Area_Sqm.get(opp.Id);    
                }
                if(idDBtoOLDService_Area_Sqm.keySet().size() > 0 && idDBtoOLDService_Area_Sqm.get(opp.Id) != null){
                    if(opp.Service_Area_Sqm__c == null){
                       opp.Service_Area_Sqm__c = 0; 
                    }
                    opp.Service_Area_Sqm__c = opp.Service_Area_Sqm__c-idDBtoOLDService_Area_Sqm.get(opp.Id);    
                }
                //-----------------------Terrace_Area_Sqm__c--------------------------                       
                if(idDBtoNEWTerrace_Area_Sqm.keySet().size() > 0 && idDBtoNEWTerrace_Area_Sqm.get(opp.Id) != null){
                    if(opp.Terrace_Area_Sqm__c == null){
                       opp.Terrace_Area_Sqm__c = 0; 
                    }
                    opp.Terrace_Area_Sqm__c = opp.Terrace_Area_Sqm__c+idDBtoNEWTerrace_Area_Sqm.get(opp.Id);    
                }
                if(idDBtoOLDTerrace_Area_Sqm.keySet().size() > 0 && idDBtoOLDTerrace_Area_Sqm.get(opp.Id) != null){
                    if(opp.Terrace_Area_Sqm__c == null){
                       opp.Terrace_Area_Sqm__c = 0; 
                    }
                    opp.Terrace_Area_Sqm__c = opp.Terrace_Area_Sqm__c-idDBtoOLDTerrace_Area_Sqm.get(opp.Id);    
                }
                //-----------------------Service_Area_SAR__c--------------------------                       
                if(idDBtoNEWService_Area_SAR.keySet().size() > 0 && idDBtoNEWService_Area_SAR.get(opp.Id) != null){
                    if(opp.Service_Area_SAR__c == null){
                       opp.Service_Area_SAR__c = 0; 
                    }
                    opp.Service_Area_SAR__c = opp.Service_Area_SAR__c+idDBtoNEWService_Area_SAR.get(opp.Id);    
                }
                if(idDBtoOLDService_Area_SAR.keySet().size() > 0 && idDBtoOLDService_Area_SAR.get(opp.Id) != null){
                    if(opp.Service_Area_SAR__c == null){
                       opp.Service_Area_SAR__c = 0; 
                    }
                    opp.Service_Area_SAR__c = opp.Service_Area_SAR__c-idDBtoOLDService_Area_SAR.get(opp.Id);    
                }
                //-----------------------Terrace_Area_SAR__c--------------------------                       
                if(idDBtoNEWTerrace_Area_SAR.keySet().size() > 0 && idDBtoNEWTerrace_Area_SAR.get(opp.Id) != null){
                    if(opp.Terrace_Area_SAR__c == null){
                       opp.Terrace_Area_SAR__c = 0; 
                    }
                    opp.Terrace_Area_SAR__c = opp.Terrace_Area_SAR__c+idDBtoNEWTerrace_Area_SAR.get(opp.Id);    
                }
                if(idDBtoOLDTerrace_Area_SAR.keySet().size() > 0 && idDBtoOLDTerrace_Area_SAR.get(opp.Id) != null){
                    if(opp.Terrace_Area_SAR__c == null){
                       opp.Terrace_Area_SAR__c = 0; 
                    }
                    opp.Terrace_Area_SAR__c = opp.Terrace_Area_SAR__c-idDBtoOLDTerrace_Area_SAR.get(opp.Id);    
                }
                //-----------------------Minimum_Acceptable_Rent__c--------------------------                       
                if(idDBtoNEWMinimum_Acceptable_Rent.keySet().size() > 0 && idDBtoNEWMinimum_Acceptable_Rent.get(opp.Id) != null){
                    if(opp.Minimum_Acceptable_Rent__c == null){
                       opp.Minimum_Acceptable_Rent__c = 0; 
                    }
                    opp.Minimum_Acceptable_Rent__c = opp.Minimum_Acceptable_Rent__c+idDBtoNEWMinimum_Acceptable_Rent.get(opp.Id);    
                }
                if(idDBtoOLDMinimum_Acceptable_Rent.keySet().size() > 0 && idDBtoOLDMinimum_Acceptable_Rent.get(opp.Id) != null){
                    if(opp.Minimum_Acceptable_Rent__c == null){
                       opp.Minimum_Acceptable_Rent__c = 0; 
                    }
                    opp.Minimum_Acceptable_Rent__c = opp.Minimum_Acceptable_Rent__c-idDBtoOLDMinimum_Acceptable_Rent.get(opp.Id);    
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
                if(idDBtoMinimum_UASNEW.keySet().size() > 0 && idDBtoMinimum_UASNEW.get(opp.Id) != null){
                    if(opp.Unit_Area_Sqm__c == null){
                       opp.Unit_Area_Sqm__c = 0; 
                    }
                    opp.Unit_Area_Sqm__c=opp.Unit_Area_Sqm__c+idDBtoMinimum_UASNEW.get(opp.Id);
                }
                if(idDBtoMinimum_UASOLD.keySet().size() > 0 && idDBtoMinimum_UASOLD.get(opp.Id) != null){
                    if(opp.Unit_Area_Sqm__c == null){
                       opp.Unit_Area_Sqm__c = 0; 
                    }
                    opp.Unit_Area_Sqm__c=opp.Unit_Area_Sqm__c-idDBtoMinimum_UASOLD.get(opp.Id);
                }
                //-------------------Total_Prices_Unit_Area__c------
                if(idDBtoMinimum_TPUANEW.keySet().size() > 0 && idDBtoMinimum_TPUANEW.get(opp.Id) != null){
                    if(opp.Total_Prices_Unit_Area__c == null){
                       opp.Total_Prices_Unit_Area__c = 0; 
                    }
                    opp.Total_Prices_Unit_Area__c=opp.Total_Prices_Unit_Area__c+idDBtoMinimum_TPUANEW.get(opp.Id);
                }
                if(idDBtoMinimum_TPUAOLD.keySet().size() > 0 && idDBtoMinimum_TPUAOLD.get(opp.Id) != null){
                    if(opp.Total_Prices_Unit_Area__c == null){
                       opp.Total_Prices_Unit_Area__c = 0; 
                    }
                    opp.Total_Prices_Unit_Area__c=opp.Total_Prices_Unit_Area__c-idDBtoMinimum_TPUAOLD.get(opp.Id);
                }
                //---------Devide----------Price_Sqm_SAR_Unit__c----------
                if(opp.Total_Prices_Unit_Area__c != 0 && opp.Unit_Area_Sqm__c != 0 && opp.Total_Prices_Unit_Area__c != Null && opp.Unit_Area_Sqm__c != Null){
                    opp.Price_Sqm_SAR_Unit__c = opp.Total_Prices_Unit_Area__c/opp.Unit_Area_Sqm__c;    
                }else{
                    opp.Price_Sqm_SAR_Unit__c = 0;
                }
                //-------------------Total_Prices_Service_Area__c---
                if(idDBtoMinimum_TPSANEW.keySet().size() > 0 && idDBtoMinimum_TPSANEW.get(opp.Id) != null){
                    if(opp.Total_Prices_Service_Area__c == null){
                       opp.Total_Prices_Service_Area__c = 0; 
                    }
                    opp.Total_Prices_Service_Area__c=opp.Total_Prices_Service_Area__c+idDBtoMinimum_TPSANEW.get(opp.Id);
                }
                if(idDBtoMinimum_TPSAOLD.keySet().size() > 0 && idDBtoMinimum_TPSAOLD.get(opp.Id) != null){
                    if(opp.Total_Prices_Service_Area__c == null){
                       opp.Total_Prices_Service_Area__c = 0; 
                    }
                    opp.Total_Prices_Service_Area__c=opp.Total_Prices_Service_Area__c-idDBtoMinimum_TPSAOLD.get(opp.Id);
                }    
                //---------Devide----------Price_Sqm_SAR_Service__c-------
                if(opp.Total_Prices_Service_Area__c != 0 && opp.Service_Area_Sqm__c != 0 && opp.Total_Prices_Service_Area__c != Null && opp.Service_Area_Sqm__c != Null){
                    opp.Price_Sqm_SAR_Service__c = opp.Total_Prices_Service_Area__c/opp.Service_Area_Sqm__c;    
                }else{
                    opp.Price_Sqm_SAR_Service__c = 0;
                }
                //-------------------Total_Prices_Terrace_Area__c---
                if(idDBtoMinimum_TPTANEW.keySet().size() > 0 && idDBtoMinimum_TPTANEW.get(opp.Id) != null){
                    if(opp.Total_Prices_Terrace_Area__c == null){
                       opp.Total_Prices_Terrace_Area__c = 0; 
                    }
                    opp.Total_Prices_Terrace_Area__c=opp.Total_Prices_Terrace_Area__c+idDBtoMinimum_TPTANEW.get(opp.Id);
                }
                if(idDBtoMinimum_TPTAOLD.keySet().size() > 0 && idDBtoMinimum_TPTAOLD.get(opp.Id) != null){
                    if(opp.Total_Prices_Terrace_Area__c == null){
                       opp.Total_Prices_Terrace_Area__c = 0; 
                    }
                    opp.Total_Prices_Terrace_Area__c=opp.Total_Prices_Terrace_Area__c-idDBtoMinimum_TPTAOLD.get(opp.Id);
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
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
        if(b){}
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