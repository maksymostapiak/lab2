#include <iostream>
#include <cstdlib>

int main() {
    const char* env_var = std::getenv("APP_ENV");
    std::string env = env_var ? env_var : "default";
    std::cout << "Lab project running! Environment: " << env << std::endl;
    return 0;
}
