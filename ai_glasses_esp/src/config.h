//BLE Defines:

#define IMG_SERVICE_UUID    "e86fa43c-5ae8-4663-abb2-889f09cfb822"
#define IMG_CONTROL_UUID    "8a80c26e-404c-4436-8877-bc643a7194c9"
#define IMG_STATUS_UUID     "13a56951-37c2-4517-98a6-353e7c5b299b"
#define IMG_DATA_UUID       "8fcc7c0e-a4c0-4f56-abcd-fb61e137aa7a"

#define CMD_SERVICE_UUID    "6d22fa7b-4f6c-4bd7-962c-a343c00060a1"
#define CMD_CMD_UUID        "06e025b3-597e-4c94-87df-c4bd1b4e0b0e"
#define CMD_BAT_UUID        "726530db-8845-4241-a10e-e26f20b095d6"

#define MTU_RATE 512
#define BUFFERSIZE 396

#define BLE_PASSKEY 123456

#define MAX_INDEX 9999

// Timeouts:
#define BLE_TIMEOUT     (15ULL)     //in s
#define PAIRING_TIMEOUT (200ULL)     //in s
#define TIME_TO_SLEEP   (60ULL)     // in s, should be 60 for final product
#define REQUEST_TIMEOUT (2ULL)      //timeout for img_state = SEND, if no commands are received for x amount of time, sends error, to "wake up" the client

#define CHUNK_TIME (100)     // time between chunks in sendImage(), kind of  an inverse of bitreate (ms)

#define BAT_PIN D0
#define VMAX    (3.3f)
#define ADC_RESOLUTION  (4095)
#define BAT_SAMPLES     (16)

#define SD_CS (21) //dont change this: it is specific to this esp32s3 model

//PAIR button:
#define PAIR_PIN D5
#define FORGET_HOLD_MS  (1000UL)
#define DEBOUNCE_MS     (50UL)