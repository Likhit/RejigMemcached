package edu.usc.cs550.rejig.experiments;

import edu.usc.cs550.rejig.interfaces.FragmentList;
import edu.usc.cs550.rejig.interfaces.RejigConfig;

import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

public class Experiment {

  public static void main(String[] args) throws InterruptedException, Exception {
    String coordinatorHost = args[1];
    int coordinatorPort = Integer.parseInt(args[2]);
    RejigWriterClient client = new RejigWriterClient(coordinatorHost, coordinatorPort);
    if (args[0].equals("constant")) {
      constantExperiment(client);
    } else if (args[0].equals("changeEveryNSecs")) {
      int clearence = Integer.parseInt(args[3]);
      int timeout = Integer.parseInt(args[4]);
      int recovery = Integer.parseInt(args[5]);
      int death = Integer.parseInt(args[6]);
      changeEveryNSecs(client, clearence, timeout, recovery, death);
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

  public static void changeEveryNSecs(RejigWriterClient client, int clearence, int timeout, int recovery, int death) throws InterruptedException {
    Random rand = new Random(23423432);
    final FragmentList init = FragmentList.newBuilder()
      .addAddress("13.68.179.205:11220").addAddress("13.68.179.205:11221")
      .addAddress("13.68.179.205:11222").addAddress("13.68.179.205:11223")
      .addAddress("13.68.179.205:11224")
      .addAddress("40.87.91.240:11220").addAddress("40.87.91.240:11221")
      .addAddress("40.87.91.240:11222").addAddress("40.87.91.240:11223")
      .addAddress("40.87.91.240:11224")
      .addAddress("40.76.37.110:11220").addAddress("40.76.37.110:11221")
      .addAddress("40.76.37.110:11222").addAddress("40.76.37.110:11223")
      .addAddress("40.76.37.110:11224")
      .addAddress("40.76.40.194:11220").addAddress("40.76.40.194:11221")
      .addAddress("40.76.40.194:11222").addAddress("40.76.40.194:11223")
      .addAddress("40.76.40.194:11224")
      .build();
    final int numFragments = init.getAddressCount();
    RejigConfig response = client.setConfig(init);
    printConfig(response);
    Thread.sleep(clearence * 1000);
    int currTime = 1;
    while (currTime < death) {
      FragmentList.Builder builder = init.toBuilder();
      int removeIndex = rand.nextInt(numFragments);
      int replaceIndex = rand.nextInt(numFragments);
      if (replaceIndex == removeIndex) {
        replaceIndex = (removeIndex + 1) % numFragments;
      }
      builder.setAddress(removeIndex, init.getAddress(replaceIndex));
      FragmentList newLs = builder.build();
      response = client.setConfig(newLs);
      printConfig(response);
      Thread.sleep(recovery * 1000);
      response = client.setConfig(init);
      printConfig(response);
      Thread.sleep((timeout - recovery) * 1000);
      currTime += timeout;
    }
  }

  private static void printConfig(RejigConfig config) {
    List<String> fragments = config.getFragmentList().stream()
      .map(f -> String.format("%s,%s", f.getId(), f.getAddress()))
      .collect(Collectors.toList());
    String str = String.format("%s\t%s", config.getId(), String.join("\t", fragments));
    System.out.println(str);
  }
}