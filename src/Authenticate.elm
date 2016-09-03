port module Authenticate exposing (..)

import Signup
import Html exposing (div, Html)
import Html.App as App


type alias Model =
    { signup : Signup.Model
    , activeUser : Maybe ActiveUserCreds
    }


type alias ActiveUserCreds =
    { token : String
    , email : String
    }


init : Maybe ActiveUserCreds -> ( Model, Cmd Msg )
init creds =
    let
        ( signupModel, signupMsgs ) =
            Signup.init
    in
        ( { signup = signupModel
          , activeUser = creds
          }
        , Cmd.batch
            [ Cmd.map Signup signupMsgs ]
          -- TODO: implement login here
        )


type Msg
    = Signup Signup.Msg
    | Logout


port setToken : Maybe ActiveUserCreds -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Signup subMsg ->
            let
                ( signup, signupCmds ) =
                    Signup.update subMsg model.signup

                creds =
                    case signup.token of
                        Just token ->
                            Just { token = token, email = signup.email }

                        Nothing ->
                            Nothing

                response =
                    case subMsg of
                        Signup.FetchSucceed arguments ->
                            ( { model | signup = signup, activeUser = creds }
                            , Cmd.batch
                                [ Cmd.map Signup signupCmds
                                , setToken creds
                                ]
                            )

                        _ ->
                            ( { model | signup = signup }
                            , Cmd.map Signup signupCmds
                            )
            in
                response

        Logout ->
            ( { model | activeUser = Nothing }
            , setToken model.activeUser
            )


view : Model -> Html Msg
view model =
    div []
        [ App.map Signup (Signup.view model.signup)
        ]



--


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
