port module Authenticate exposing (..)

import Signup
import Login
import Html exposing (div, Html)
import Html.App as App


type alias Model =
    { signup : Signup.Model
    , login : Login.Model
    , activeUser : Maybe ActiveUserCreds
    }


type Display
    = SignupView
    | LoginView


type alias ActiveUserCreds =
    { token : String
    , email : String
    }


init : Maybe ActiveUserCreds -> ( Model, Cmd Msg )
init creds =
    let
        ( signupModel, signupMsgs ) =
            Signup.init

        ( loginModel, loginMsgs ) =
            Login.init
    in
        ( { signup = signupModel
          , login = Login.initialModel
          , activeUser = creds
          }
        , Cmd.batch
            [ Cmd.map Signup signupMsgs
            , Cmd.map Login Cmd.none
            ]
        )


emptyModel : Model
emptyModel =
    Model Signup.initialModel Login.initialModel Nothing


type Msg
    = Signup Signup.Msg
    | Login Login.Msg
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

        Login subMsg ->
            let
                ( login, loginCmds ) =
                    Login.update subMsg model.login

                creds =
                    case login.token of
                        Just token ->
                            Just { token = token, email = login.email }

                        Nothing ->
                            Nothing

                response =
                    case subMsg of
                        Login.FetchSucceed arguments ->
                            ( { model | login = login, activeUser = creds }
                            , Cmd.batch
                                [ Cmd.map Login loginCmds
                                , setToken creds
                                ]
                            )

                        _ ->
                            ( { model | login = login }
                            , Cmd.map Login loginCmds
                            )
            in
                response

        Logout ->
            ( { model | activeUser = Nothing }
            , setToken model.activeUser
            )


logout model =
    update Logout model


view : Model -> Display -> Html Msg
view model view =
    case view of
        SignupView ->
            div []
                [ App.map Signup (Signup.view model.signup)
                ]

        LoginView ->
            div []
                [ App.map Login (Login.view model.login)
                ]
