package dao;

import java.util.Map;
/**
Base model class to hold the Activity coming from Firebase 
*/
public class Activity {

    public static String TYPE_TAP = "tap";
    public static String TYPE_SCROLL = "scroll";
    public static String TYPE_DISTRACTED = "distracted";
    public static String TYPE_LOOKING = "looking";
    public static String TYPE_URL_CHANGE = "url_change";

    private String type;
    private long timeStamp;
    private Map<String, Object> metaData;

    public Activity() {

    }

    public Activity(String type, long timeStamp, Map<String, Object> metaData) {
        this.type = type;
        this.timeStamp = timeStamp;
        this.metaData = metaData;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public long getTimeStamp() {
        return timeStamp;
    }

    public void setTimeStamp(long timeStamp) {
        this.timeStamp = timeStamp;
    }

    public Map<String, Object> getMetaData() {
        return metaData;
    }

    public void setMetaData(Map<String, Object> metaData) {
        this.metaData = metaData;
    }

    @Override
    public String toString() {
        return "Activity{" +
                "type='" + type + '\'' +
                ", timeStamp=" + timeStamp +
                ", metaData=" + metaData +
                '}';
    }
}
