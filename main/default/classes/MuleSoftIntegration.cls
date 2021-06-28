public without sharing class MuleSoftIntegration {

    private static Mulesoft_Integration_Settings__mdt muleSettings = retrieveMulesoftSettings();

    public static VehicleResult getVehicle(String truckVIN) {
        VehicleResult truckInfo = new VehicleResult();

        try {
            String endpoint = String.format(muleSettings.Get_Vehicle_Endpoint__c, new List<Object>{truckVIN});

            HTTPResponse response = null;

            HTTPRequest req = new HTTPRequest();
            req.setHeader(LT_Constants.CLIENT_ID, muleSettings.Client_Id__c);
            req.setHeader(LT_Constants.CLIENT_SECRET, muleSettings.Client_Secret__c);
            req.setHeader(LT_Constants.CORRELATION_ID, muleSettings.Correlation_Id__c);
            req.setEndpoint(endpoint);
            if (muleSettings.Request_Timeout__c != null) {
                req.setTimeout(Integer.valueOf(muleSettings.Request_Timeout__c));
            }
            req.setMethod(LT_Constants.GET);

            //Make API call
            response = new Http().send(req);

            if (response.getStatusCode() == 200) {
                String jsonResponse = response.getBody();
                truckInfo = (VehicleResult) JSON.deserialize(jsonResponse, VehicleResult.class);
            }

        } catch(Exception e) {
            //Throw custom Exception / Store into custom Debug Log object
            System.debug('[MuleSoftIntegration.getVehicle]: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        return truckInfo;
    }


    public static Mulesoft_Integration_Settings__mdt retrieveMulesoftSettings() {
        if (muleSettings == null){
            muleSettings = [
                          SELECT Client_Id__c, Client_Secret__c, Correlation_Id__c,
                                Get_Vehicle_Endpoint__c, Request_Timeout__c
                          FROM Mulesoft_Integration_Settings__mdt 
                          WHERE QualifiedApiName = :LT_Constants.MULESOFT_INTEGRATION_SETTINGS
              ];
          }
          
          return muleSettings;
    }


    public class VehicleResult {
        @AuraEnabled
        public String vin {get; set;}
        @AuraEnabled
        public String vehicleNum {get; set;}
        @AuraEnabled
        public String vehicleRegNum {get; set;}
        @AuraEnabled
        public String regNumCountryKey {get; set;}
        @AuraEnabled
        public String oemVin {get; set;}
        @AuraEnabled
        public String manufacturer {get; set;}
        @AuraEnabled
        public String prodCode {get; set;}
        @AuraEnabled
        public String modelRange {get; set;}
        @AuraEnabled
        public String vehicleType {get; set;}
        @AuraEnabled
        public String typeVariant {get; set;}
        @AuraEnabled
        public String deliveryExWorkDate {get; set;}
        @AuraEnabled
        public String firstRegDate {get; set;}
        @AuraEnabled
        public String wheelBase {get; set;}
        @AuraEnabled
        public String overhang {get; set;}
        @AuraEnabled
        public String suspension {get; set;}
        @AuraEnabled
        public String truckAxle {get; set;}
        @AuraEnabled
        public String customerRegDate {get; set;}
        @AuraEnabled
        public String customerNo {get; set;}
        @AuraEnabled
        public String customerName {get; set;}
        @AuraEnabled
        public MeasuringPointWrapper measuringPoint {get; set;}
        @AuraEnabled
        public VehicleTextWrapper vehicleTextData {get; set;}

    }

    public class MeasuringPointWrapper {
        @AuraEnabled
        public String measPoint {get; set;}
        @AuraEnabled
        public String counterReading {get; set;}
        @AuraEnabled
        public String mpUnit {get; set;}
    }

    public class VehicleTextWrapper {
        @AuraEnabled
        public InformationTextWrapper informationText {get; set;}
        @AuraEnabled
        public List<NoteTextWrapper> noteText {get; set;}
    }

    public class InformationTextWrapper {
        @AuraEnabled
        public String textLine {get; set;}
    }

    public class NoteTextWrapper {
        @AuraEnabled
        public String tagColumn {get; set;}
        @AuraEnabled
        public String textLine {get; set;}
    }
}