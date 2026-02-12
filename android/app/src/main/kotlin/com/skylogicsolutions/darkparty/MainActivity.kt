package com.skylogicsolutions.darkparty

import android.os.Bundle
import com.google.firebase.FirebaseApp
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        try {
            FirebaseApp.initializeApp(this)
        } catch (e: Exception) { /* already initialized or continue */ }
        super.onCreate(savedInstanceState)
    }
}
