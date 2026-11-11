package com.example.monitoramentohidrometeorologico.data;

/**
 * Resposta assíncrona do repositório. Os dois métodos são chamados na thread principal,
 * então a tela pode atualizar as Views direto dentro deles.
 */
public interface Callback<T> {
    void onSucesso(T resultado);

    void onErro(ErroDados erro);
}
