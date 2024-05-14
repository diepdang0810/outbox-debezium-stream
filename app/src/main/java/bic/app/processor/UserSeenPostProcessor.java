package bic.app.processor;

import bic.app.dto.ReactionCreated;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.serialization.Serializer;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.Produced;
import org.codehaus.jackson.node.JsonNodeFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.support.serializer.JsonSerde;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class UserSeenPostProcessor {

    public static String STREAM_TOPIC = "outbox.event.reaction";
    public static String STREAM_OUTPUT_TOPIC = "stream.output";

    @Autowired
    private  StreamsBuilder streamBuilder;

    @PostConstruct
    public void streamTopology(){
        JsonSerde<ReactionCreated> reactionCreatedJsonSerde = new JsonSerde<>(ReactionCreated.class);
        KStream<String, ReactionCreated> kstream = streamBuilder.stream("outbox.event.reaction", Consumed.with(Serdes.String(), reactionCreatedJsonSerde));
        kstream.peek((k, v) -> System.out.println("key: " + k + " Value: " + v.getContentId()))
                //.groupByKey()
//                .aggregate(
//                        () -> 0L,
//                        (key, transaction, balance) -> transaction.getReactionName()
//                )
                .to("stream.output",Produced.with(Serdes.String(),  reactionCreatedJsonSerde));
    }
}
