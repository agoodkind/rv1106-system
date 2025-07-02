#include <stdio.h>
#include <stdlib.h>

int main() {
    printf("Hello from Rockchip RV1106!\n");
    printf("Compiled with: %s\n", __VERSION__);
    printf("Target: ARM %s\n", 
        #ifdef __ARM_ARCH_5TE__
            "ARMv5TE"
        #elif defined(__ARM_ARCH_7A__)
            "ARMv7-A"
        #else
            "Unknown"
        #endif
    );
    printf("Float ABI: %s\n",
        #ifdef __ARM_PCS_VFP
            "Hard Float"
        #else
            "Soft Float"
        #endif
    );
    return 0;
} 