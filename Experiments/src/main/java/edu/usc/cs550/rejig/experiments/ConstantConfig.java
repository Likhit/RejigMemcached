package edu.usc.cs550.rejig.experiments;

import edu.usc.cs550.rejig.interfaces.FragmentList;
import edu.usc.cs550.rejig.interfaces.RejigConfig;
import edu.usc.cs550.rejig.interfaces.RejigWriterGrpc;

import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import io.grpc.StatusRuntimeException;

import java.util.concurrent.TimeUnit;

public class ConstantConfig {
  private ManagedChannel channel;

  private RejigWriterGrpc.RejigWriterBlockingStub blockingStub;

  public ConstantConfig(String host, int port) {
    this(ManagedChannelBuilder.forAddress(host, port)
      .usePlaintext()
      .build()
    );
  }

  ConstantConfig(ManagedChannel channel) {
    this.channel = channel;
    blockingStub = RejigWriterGrpc.newBlockingStub(channel);
  }

  public void shutDown() {
    try {
      if (channel != null) {
        channel.shutdown().awaitTermination(5, TimeUnit.SECONDS);
        channel = null;
      }
    } catch (InterruptedException e) {
      throw new RuntimeException(e);
    }
  }

  public RejigConfig setConfig(FragmentList list) {
    RejigConfig response;
    try {
      response = blockingStub.setConfig(list);
    } catch (StatusRuntimeException e) {
      throw new RuntimeException(e);
    }
    return response;
  }

  public static void main(String[] args) {
    FragmentList ls = FragmentList.newBuilder()
      .addAddress("localhost:11212")
      .addAddress("localhost:11213")
      .build();
    ConstantConfig exp = new ConstantConfig("localhost", 50031);
    RejigConfig response = exp.setConfig(ls);
    System.out.println(response.toString());
  }
}