#ifndef ENCRYPTOR_H
#define ENCRYPTOR_H

// 最大字符串长度
#define MAX_LEN 32

// Encryptor 结构体，封装加密和解密函数
typedef struct {
    int (*encrypt)(const char* input, char* output);
    int (*decrypt)(const char* input, char* output);
} Encryptor;

// 创建并初始化 Encryptor 实例
Encryptor Encryptor_create();

#endif // ENCRYPTOR_H