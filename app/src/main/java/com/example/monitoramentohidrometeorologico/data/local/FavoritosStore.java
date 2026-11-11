package com.example.monitoramentohidrometeorologico.data.local;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.annotation.NonNull;

import java.util.HashSet;
import java.util.Set;

/**
 * Estações favoritas guardadas no aparelho (HM-05). Persistem ao fechar o app.
 */
public class FavoritosStore {

    private static final String PREFS = "favoritos";
    private static final String CHAVE = "codigos";

    private final SharedPreferences prefs;

    public FavoritosStore(Context context) {
        this.prefs = context.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    @NonNull
    public synchronized Set<String> getTodos() {
        // cópia: o Set devolvido pelo SharedPreferences não pode ser alterado
        return new HashSet<>(prefs.getStringSet(CHAVE, new HashSet<>()));
    }

    public boolean contem(@NonNull String codigo) {
        return getTodos().contains(codigo);
    }

    public synchronized void definir(@NonNull String codigo, boolean favorita) {
        Set<String> atual = getTodos();
        boolean mudou = favorita ? atual.add(codigo) : atual.remove(codigo);
        if (mudou) prefs.edit().putStringSet(CHAVE, atual).apply();
    }
}
