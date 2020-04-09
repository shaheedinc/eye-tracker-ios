import com.google.api.core.ApiFuture;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import dao.Activity;
import dao.Test;

import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

/**
This generates a CSV file based on the records in Firebase
*/
public class Main {

    // Variable to hold individual tests
    private List<Test> tests = new ArrayList<>();

    public static void main(String[] args) {
        new Main().run();
    }

    private void run() {
        // Initializing firebase to read the documents
        try {
            FileInputStream serviceAccount = new FileInputStream("eyetrack-4e6b3-firebase-adminsdk-aporm-b730fee2ef.json");
            FirebaseOptions options = new FirebaseOptions.Builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .setDatabaseUrl("https://eyetrack-4e6b3.firebaseio.com")
                    .build();

            FirebaseApp.initializeApp(options);

            Firestore db = FirestoreClient.getFirestore();

            //Getting all the tests from Firebase
            ApiFuture<QuerySnapshot> query = db.collection("tests").get();

            QuerySnapshot querySnapshot = query.get();
            List<QueryDocumentSnapshot> documents = querySnapshot.getDocuments();
            // Parsing the documents and adding them to our list to process
            for (QueryDocumentSnapshot document : documents) {
                Test test = document.toObject(Test.class);
                test.setId(document.getId());
                tests.add(test);
            }

            System.out.println("Got " + tests.size() + " test data");

            System.out.println("Preparing CSV file(s)");

            int testCount = 1;
            // Parsing each individual test separately
            for(Test test: tests) {
                //Generating a new csv file to hold the results
                FileWriter fileWriter = new FileWriter("parsedData/" + test.getParticipantId() + "-" + test.getId() + ".csv");
                // Setting the column names
                fileWriter.append("Type");
                fileWriter.append(",");
                fileWriter.append("Time Stamp (ms)");
                fileWriter.append(",");
                fileWriter.append("Test Start");
                fileWriter.append(",");
                fileWriter.append("Distracted Period (ms)");
                fileWriter.append(",");
                fileWriter.append("Resumed Period (ms)");
                fileWriter.append(",");
                fileWriter.append("Referer URL");
                fileWriter.append(",");
                fileWriter.append("Target URL");
                fileWriter.append("\n");

                // Variables used to calculate distraction time
                boolean wasDistracted = false;
                long distractionStartTime = 0;
                long distractionEndTime = 0;
                boolean firstTapDetected = false;
                boolean lookedBackInDisplay = false;
                // Adding each activities separately
                for (Activity activity: test.getActivities()) {
                    fileWriter.append(activity.getType());
                    fileWriter.append(",");
                    fileWriter.append(String.valueOf(activity.getTimeStamp()));

                    fileWriter.append(",");
                    if (activity.getType().equalsIgnoreCase(Activity.TYPE_TAP) && !firstTapDetected) {
                        firstTapDetected = true;
                        fileWriter.append("Here");
                    }

                    fileWriter.append(",");
                    if (activity.getType().equalsIgnoreCase(Activity.TYPE_DISTRACTED)) {
                        wasDistracted = true;
                        distractionStartTime = activity.getTimeStamp();
                    } else if (activity.getType().equalsIgnoreCase(Activity.TYPE_LOOKING) && wasDistracted) {
                        fileWriter.append(String.valueOf(activity.getTimeStamp() - distractionStartTime));
                        wasDistracted = false;
                        distractionStartTime = 0;
                        distractionEndTime = activity.getTimeStamp();

                        lookedBackInDisplay = true;
                    }

                    fileWriter.append(",");
                    if (lookedBackInDisplay) {
                        if (activity.getType().equalsIgnoreCase(Activity.TYPE_TAP)
                                || activity.getType().equalsIgnoreCase(Activity.TYPE_SCROLL)) {
                            fileWriter.append(String.valueOf(activity.getTimeStamp()-distractionEndTime));

                            distractionEndTime = 0;
                            lookedBackInDisplay = false;
                        }
                    }

                    if (activity.getType().equalsIgnoreCase(Activity.TYPE_URL_CHANGE)) {
                        fileWriter.append(",");
                        fileWriter.append(activity.getMetaData().get("fromURL").toString());
                        fileWriter.append(",");
                        fileWriter.append(activity.getMetaData().get("toURL").toString());
                    } else {
                        fileWriter.append(",");
                        fileWriter.append(",");
                    }

                    fileWriter.append("\n");
                }

                // Closing the file
                fileWriter.flush();
                fileWriter.close();
                System.out.println("Done parsing test: "+(testCount++));
            }
        } catch (IOException | ExecutionException | InterruptedException e) {
            e.printStackTrace();
        }
    }

}
