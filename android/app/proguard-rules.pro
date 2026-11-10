# Regras extras do R8 (o Flutter aplica este arquivo automaticamente no build release).

# WorkManager (usado pelo SDK de anúncios do Google) cria o banco Room por
# reflexão: sem isto o app fecha ao abrir ("Failed to create an instance of
# androidx.work.impl.WorkDatabase").
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
