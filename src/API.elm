module API exposing (..)

import Http
import Json.Decode as Json exposing ((:=))
import Json.Encode as JS
import Task


-- Loggedout API
-- Login API

submitLoginData : ( String, String ) -> Task.Task Http.Error ( Maybe String, Maybe String )
submitLoginData ( email, password ) =
    let
        url =
            "http://localhost:4567/elm-login.json"

        body =
            Http.stringData "user"
                (JS.encode 0
                    (JS.object
                        [ ( "email", JS.string email )
                        , ( "pw", JS.string password )
                        ]
                    )
                )
    in
        Http.post decodeLoginResponse url (Http.multipart [ body ])


decodeLoginResponse : Json.Decoder ( Maybe String, Maybe String )
decodeLoginResponse =
    Json.object2 (,)
        (Json.maybe
            ("token" := Json.string)
        )
        (Json.maybe
            ("errors" := Json.string)
        )

--Signup API

submitSignupData : (String, String, String) -> Task.Task Http.Error ( Maybe String, List String )
submitSignupData (email, password, passwordAgain) =
    let
        url =
            "http://localhost:4567/elm-signup.json"

        body =
            Http.stringData "user"
                (JS.encode 0
                    (JS.object
                        [ ( "email", JS.string email )
                        , ( "pw", JS.string password )
                        , ( "pw2", JS.string passwordAgain )
                        ]
                    )
                )
    in
        Http.post decodeSignUpResponse url (Http.multipart [ body ])


decodeSignUpResponse : Json.Decoder ( Maybe String, List String )
decodeSignUpResponse =
    Json.object2 (,)
        (Json.maybe
            ("token" := Json.string)
        )
        ("errors" := Json.list Json.string)

