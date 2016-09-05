module Login exposing (..)

import Html exposing (..)
import Html.Attributes exposing (href, type', placeholder, class, style)
import Html.Events exposing (onInput, onClick)
import Http
import API
import Task
import String exposing (isEmpty)
import List exposing (map, concat, concatMap)


-- MODEL


type alias Model =
    { email : String
    , password : String
    , token : Maybe String
    , errors : Errors
    }


type alias Errors =
    { email : Maybe String
    , password : Maybe String
    , server : Maybe String
    }


initialErrors : Errors
initialErrors =
    Errors Nothing Nothing Nothing


initialModel : Model
initialModel =
    Model "" "" Nothing initialErrors


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



-- UPDATE


type Msg
    = Email String
    | Password String
    | Validate
    | FetchSucceed ( Maybe String, Maybe String )
    | FetchFail Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Email email ->
            ( { model
                | email = email
              }
            , Cmd.none
            )

        Password password ->
            ( { model
                | password = password
              }
            , Cmd.none
            )

        Validate ->
            let
                newModel =
                    validate model

                cmd =
                    if isValid newModel then
                        Task.perform FetchFail FetchSucceed (API.submitLoginData ( newModel.email, newModel.password ))
                    else
                        Cmd.none
            in
                ( newModel
                , cmd
                )

        FetchSucceed ( token, errors ) ->
            ( { model
                | token = token
                , errors = Errors Nothing Nothing errors
              }
            , Cmd.none
            )

        FetchFail token ->
            ( { model
                | token = Nothing
                , errors = { email = Nothing, password = Nothing, server = Just "there was a problem connecting to the server. please try again." }
              }
            , Cmd.none
            )


validate : Model -> Model
validate model =
    let
        newErrors =
            { email =
                if isEmpty model.email then
                    Just "Enter an email address"
                    -- TO DO: Validate email format
                else
                    Nothing
            , password =
                if isEmpty model.password then
                    Just "Enter your password!"
                else
                    Nothing
            , server =
                Nothing
            }
    in
        { model | errors = newErrors }


isValid : Model -> Bool
isValid model =
    model.errors.email == Nothing && model.errors.password == Nothing


-- VIEW


view : Model -> Html Msg
view model =
    let
        serverErrors =
            case model.errors.server of
                Just error ->
                    [ div [ class "validation-error", style [ ( "color", "red " ) ] ]
                        [ text error ]
                    ]

                Nothing ->
                    []

        body =
            validatedInput [ ( "Email", "text", Email ) ] model.errors.email
                ++ validatedInput [ ( "Password", "password", Password ) ] model.errors.password
                ++ [ button [ onClick Validate ] [ text "Submit" ]
                   ]
                ++ serverErrors
                ++ [ div []
                        [ text "want to create an account? you can always just "
                        , a [ href "#signup" ] [ text "signup" ]
                        ]
                   ]
    in
        div [] body


validatedInput : List ( String, String, String -> Msg ) -> Maybe String -> List (Html Msg)
validatedInput list error =
    let
        inputFields =
            concatMap (\( a, b, c ) -> [ input [ type' b, placeholder a, onInput c ] [] ]) list

        errorFields =
            case error of
                Just msg ->
                    [ div [ class "validation-error", style [ ( "color", "red" ) ] ] [ text msg ] ]

                Nothing ->
                    []
    in
        inputFields ++ errorFields
