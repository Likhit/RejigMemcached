package edu.usc.cs550.rejig.experiments;

import edu.usc.cs550.rejig.interfaces.FragmentList;
import edu.usc.cs550.rejig.interfaces.RejigConfig;

import java.util.Random;

public class Experiment {

  public static void main(String[] args) throws InterruptedException, Exception {
    int coordinatorPort = Integer.parseInt(args[1]);
    RejigWriterClient client = new RejigWriterClient("localhost", coordinatorPort);
    if (args[0].equals("constant")) {
      constantExperiment(client);
    } else if (args[0].equals("changeEveryNSecs")) {
      int timeout = Integer.parseInt(args[2]);
      int recovery = Integer.parseInt(args[3]);
      changeEveryNSecs(client, timeout, recovery);
    }
  }

  public static void constantExperiment(RejigWriterClient client) {
    FragmentList ls = FragmentList.newBuilder()
      .addAddress("localhost:11212")
      .addAddress("localhost:11213")
      .build();
    RejigConfig response = client.setConfig(ls);
    System.out.println(response.toString());
  }

  public static void changeEveryNSecs(RejigWriterClient client, int timeout, int recovery) throws InterruptedException {
    Random rand = new Random();
    final FragmentList init = FragmentList.newBuilder()
      .addAddress("localhost:11210")
      .addAddress("localhost:11211")
      .addAddress("localhost:11212")
      .addAddress("localhost:11213")
      .addAddress("localhost:11214")
      .addAddress("localhost:11215")
      .addAddress("localhost:11216")
      .addAddress("localhost:11217")
      .addAddress("localhost:11218")
      .addAddress("localhost:11219")
      .build();
    final int numFragments = init.getAddressCount();
    while (true) {
      RejigConfig response = client.setConfig(init);
      System.out.println(response.toString());
      Thread.sleep(timeout * 1000);
      FragmentList.Builder builder = init.toBuilder();
      int removeIndex = rand.nextInt(numFragments);
      int replaceIndex = rand.nextInt(numFragments);
      if (replaceIndex == removeIndex) {
        replaceIndex = (removeIndex + 1) % numFragments;
      }
      builder.setAddress(removeIndex, init.getAddress(replaceIndex));
      FragmentList newLs = builder.build();
      response = client.setConfig(newLs);
      System.out.println(response.toString());
      Thread.sleep(recovery * 1000);
    }
  }
}