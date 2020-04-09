package dao;

import java.util.List;
/**
Base model class to hold the tests coming from Firebase
*/
public class Test {

    private String id;
    private String participantId;
    private List<Activity> activities;
    private long createdAt;
    private long updatedAt;

    public Test() {

    }

    public Test(String id, String participantId, List<Activity> activities, long createdAt, long updatedAt) {
        this.id = id;
        this.participantId = participantId;
        this.activities = activities;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getParticipantId() {
        return participantId;
    }

    public void setParticipantId(String participantId) {
        this.participantId = participantId;
    }

    public List<Activity> getActivities() {
        return activities;
    }

    public void setActivities(List<Activity> activities) {
        this.activities = activities;
    }

    public long getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(long createdAt) {
        this.createdAt = createdAt;
    }

    public long getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(long updatedAt) {
        this.updatedAt = updatedAt;
    }

    @Override
    public String toString() {
        return "Test{" +
                "id='" + id + '\'' +
                ", participantId='" + participantId + '\'' +
                ", activities=" + activities +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }
}
