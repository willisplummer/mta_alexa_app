module Login exposing (..)

import Html exposing (..)
import Html.Attributes exposing (href, type', placeholder, class, style)
import Html.Events exposing (onInput, onClick)
import Http
import Json.Decode as Json exposing ((:=))
import Json.Encode as JS
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
    , server : List String
    }


initialErrors : Errors
initialErrors =
    Errors Nothing Nothing []


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
    | FetchSucceed ( Maybe String, List String )
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
                        submitData newModel
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
                , errors = { email = Nothing, password = Nothing, server = [ "there was a problem connecting to the server. please try again." ] }
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
                []
            }
    in
        { model | errors = newErrors }


isValid : Model -> Bool
isValid model =
    model.errors.email == Nothing && model.errors.password == Nothing



-- HTTP


submitData : Model -> Cmd Msg
submitData model =
    let
        url =
            "http://localhost:4567/elm-login.json"

        body =
            Http.stringData "user"
                (JS.encode 0
                    (JS.object
                        [ ( "email", JS.string model.email )
                        , ( "pw", JS.string model.password )
                        ]
                    )
                )
    in
        Task.perform FetchFail FetchSucceed (Http.post decodeSignUpResponse url (Http.multipart [ body ]))


decodeSignUpResponse : Json.Decoder ( Maybe String, List String )
decodeSignUpResponse =
    Json.object2 (,)
        (Json.maybe
            ("token" := Json.string)
        )
        ("errors" := Json.list Json.string)



-- VIEW


view : Model -> Html Msg
view model =
    let
        serverErrors =
            if List.isEmpty model.errors.server then
                []
            else
                [ div [ class "validation-error", style [ ( "color", "red " ) ] ]
                    (List.map (\str -> text str) model.errors.server)
                ]

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
