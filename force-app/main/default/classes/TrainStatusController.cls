/**
 * @description       Controller to fetch train details and live status using external API callouts.
 *                    Uses Named Credentials for secure endpoint management.
 */
public with sharing class TrainStatusController {

    /**
     * @description Sends an HTTP GET request using the given endpoint.
     * @param endpoint The full endpoint URL for the callout.
     * @return HttpResponse object containing the response from the callout.
     */
    private static HttpResponse sendHttpRequest(String endpoint) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(endpoint);
        httpRequest.setMethod('GET');
        httpRequest.setHeader('accept', 'application/json');
        httpRequest.setTimeout(120000);

        Http http = new Http();
        HttpResponse httpResponse = http.send(httpRequest);

        if (httpResponse == null || String.isBlank(httpResponse.getBody())) {
            throw new AuraHandledException('Empty or null response from endpoint: ' + endpoint);
        }

        if (httpResponse.getStatusCode() >= 400) {
            throw new AuraHandledException('Error from endpoint (' + httpResponse.getStatusCode() + '): ' + httpResponse.getBody());
        }

        return httpResponse;
    }

    /**
     * @description Fetches the train name based on a given train number.
     * @param trainNumber The train number whose name needs to be fetched.
     * @return The name of the train or the train number if not found.
     */
    public static String getTrainName(String trainNumber) {
        try {
            String endpoint = 'callout:TrainStatusRappid_NC?train_no=' + trainNumber;
            HttpResponse response = sendHttpRequest(endpoint);

            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (responseMap != null && responseMap.containsKey('train_name')) {
                return (String) responseMap.get('train_name');
            }
            return trainNumber;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching train name: ' + e.getMessage());
        }
    }

    /**
     * @description Fetches the live status of a train based on train number
     * @param trainNumber The train number whose live status is required.
     * @return A TrainStatusResponse object containing train status details.
     */
    @AuraEnabled
    public static TrainStatusResponse getTrainLiveStatus(String trainNumber) {
        try {
            // Convert Date to required API format (YYYYMMDD)
            String formattedDate = String.valueOf(System.today()).remove('-');

            // Build endpoint dynamically
            String endpoint = 'callout:IRCTC_NC/api/trains/v1/train/status?client=web&train_number=' 
                            + trainNumber + '&departure_date=' + formattedDate;

            HttpResponse response = sendHttpRequest(endpoint);

            // Deserialize API response into wrapper
            TrainStatusResponse trainStatusResponse = (TrainStatusResponse) JSON.deserialize(response.getBody(), TrainStatusResponse.class);

            // Fetch and assign train name
            if (trainStatusResponse != null && trainStatusResponse.body != null) {
                trainStatusResponse.body.train_name = getTrainName(trainNumber);
            }

            return trainStatusResponse;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching live train status: ' + e.getMessage());
        }
    }

    // WRAPPER CLASSES

    public class TrainStatusResponse {
        @AuraEnabled public String error;
        @AuraEnabled public StatusWrapper status;
        @AuraEnabled public Body body;
        @AuraEnabled public Map<String, Object> meta;
        @AuraEnabled public Integer code;
        @AuraEnabled public Integer internal_code;
    }

    public class StatusWrapper {
        @AuraEnabled public String result;
        @AuraEnabled public Message message;
    }

    public class Message {
        @AuraEnabled public String title;
        @AuraEnabled public String message;
    }

    public class Body {
        @AuraEnabled public String train_name;
        @AuraEnabled public String time_of_availability;
        @AuraEnabled public String current_station;
        @AuraEnabled public Boolean terminated;
        @AuraEnabled public String server_timestamp;
        @AuraEnabled public String train_status_message;
        @AuraEnabled public List<Station> stations;
    }

    public class Station {
        @AuraEnabled public String arrivalTime;
        @AuraEnabled public String dayCount;
        @AuraEnabled public String departureTime;
        @AuraEnabled public String distance;
        @AuraEnabled public String haltTime;
        @AuraEnabled public String routeNumber;
        @AuraEnabled public String stationCode;
        @AuraEnabled public String stationName;
        @AuraEnabled public String stnSerialNumber;
        @AuraEnabled public String actual_arrival_date;
        @AuraEnabled public String actual_arrival_time;
        @AuraEnabled public String actual_departure_date;
        @AuraEnabled public String actual_departure_time;
        @AuraEnabled public String expected_platform;
    }
}