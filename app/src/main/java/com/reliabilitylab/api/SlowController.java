package com.reliabilitylab.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class SlowController {

    @GetMapping("/slow")
    public Map<String, Object> slow(@RequestParam(defaultValue = "2000") long millis)
            throws InterruptedException {
        long start = System.currentTimeMillis();
        Thread.sleep(millis);
        long elapsed = System.currentTimeMillis() - start;
        return Map.of("requestedMillis", millis, "actualMillis", elapsed);
    }
}
