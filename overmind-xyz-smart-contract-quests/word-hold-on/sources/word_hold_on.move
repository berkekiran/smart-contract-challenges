/*
    The quest is an on-chain representation of the classic Wordle game.
    A player has to guess the hashed word (`ANSWER_HASH`) with only 6 guesses calling `guess_word` function.
    After each guess a player can call `get_guess_attempts` function to get a list of their guess attempts. Each of the
    records in the list consists of a SimpleMap mapping a hash of each of the letters of the word provided to
    `guess_word` function to a boolean value representing either if the player provided a correct letter for that
    precise position (true) or an incorrect letter (false). If the word provided to `guess_word` function is correct,
    the player is transferred `PRIZE` amount of APT as a reward for completing the game.
*/
module overmind::word_hold_on {
    //==============================================================================================
    // Dependencies
    //==============================================================================================

    use std::bcs;
    use std::hash;
    use std::option::{Self, Option};
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;
    #[test_only]
    use aptos_framework::aptos_coin;
    #[test_only]
    use aptos_framework::guid;

    //==============================================================================================
    // Constants
    //==============================================================================================

    const ANSWER_LENGTH: u64 = 8;
    const ANSWER_HASH: vector<u8> = x"60c4004508ddcd8d1b0ea1c56ed1e5679d756d72e40f1a00820dbe5d9f69ff63";
    const FIRST_LETTER_HASH: vector<u8> = x"3eecb4a5c11c8bab18ddad1d268c827aaabb17c83f51869832a5af15efdedfcb";
    const SECOND_LETTER_HASH: vector<u8> = x"e63a84c18447bfca5c67b20a58fc6a4fefa762e4fa0e6b3b2e46f64daba345e5";
    const THIRD_LETTER_HASH: vector<u8> = x"d034b2b544e4ffb619a9c156ae578fe21f38eb0997f097ca9569807ca157f4f6";
    const FOURTH_LETTER_HASH: vector<u8> = x"6920014bef534e7eea89545a50d6aef0921f1972efcddce9f22f04a45b47d472";
    const FIFTH_LETTER_HASH: vector<u8> = x"c837f30e97185c362830b324e58a3e6782095ee8457109b27f03819ff516e121";
    const SIXTH_LETTER_HASH: vector<u8> = x"c837f30e97185c362830b324e58a3e6782095ee8457109b27f03819ff516e121";
    const SEVENTH_LETTER_HASH: vector<u8> = x"345baaa13bbe3a40695db7697fbe3f64206323b77cf3635902106f9f29667361";
    const EIGHTH_LETTER_HASH: vector<u8> = x"037f4095baddc6f37fde4740c304b1691512d2fc9cf7ede8a93b8c9ec3d1fe07";

    const ATTEMPTS_LIMIT: u64 = 6;
    const PRIZE: u64 = 1000000000; // 10 APT
    const SEED: vector<u8> = b"Wordle";

    //==============================================================================================
    // Error codes
    //==============================================================================================

    const EInsufficientAptBalance: u64 = 0;
    const EAttemptsLimitReached: u64 = 1;
    const ELetterIndexOutOfBounds: u64 = 2;
    const EInccorectWordLength: u64 = 3;

    //==============================================================================================
    // Functional structs
    //==============================================================================================

    /*
        Resource holding config of the smart contract
    */
    struct State has key {
        // Resource account's SingerCapability
        cap: SignerCapability
    }

    /*
        Resource holding data about a player's made attempts of guessing the correct word, outcome of the game
        and events
    */
    struct Player has key {
        // A SimpleMap instance holding data about made attempts and their outcomes. The key of the outer SimpleMap is
        // a counter being from a range of 0 (inclusive) to `ATTEMPTS_LIMIT` (exclusive). Each key of the inner
        // SimpleMap is a SHA3_256 hash of the corresponding letter of the word provided in `guess_word` function
        attempts: SimpleMap<u8, SimpleMap<vector<u8>, bool>>,
        // Option instance indicating either the player can still try to guess the word (option::none), the word was not
        // guessed and there are no more guess attempts (option::some(false)) or the word was guessed correctly
        // (option::some(true))
        word_guessed: Option<bool>,
        // Events
        guess_word_attempt_events: EventHandle<GuessWordAttemptEvent>,
        submit_correct_answer_events: EventHandle<SubmitCorrectAnswerEvent>
    }

    //==============================================================================================
    // Event structs
    //==============================================================================================

    /*
        Event emitted in every `guess_word` function call if the provided word is incorrect
    */
    struct GuessWordAttemptEvent has store, drop {
        // Number of the attempt
        attempt: u8,
        // Word provided to `guess_word` function
        word: String,
        // SimpleMap instance mapping a hash of each letter to a boolean value representing if the letter is correct
        // (true) or not (false)
        letter_correctness: SimpleMap<vector<u8>, bool>,
        // Timestamp, when the event was created
        event_creation_timestamp_seconds: u64
    }

    /*
        Event emitted in `guess_word` function call when the provided word is correct
    */
    struct SubmitCorrectAnswerEvent has store, drop {
        // Number of the attempt
        attempt: u64,
        // Timestamp, when the event was created
        event_creation_timestamp_seconds: u64
    }

    //==============================================================================================
    // Functions
    //==============================================================================================

    /*
        Function called when the deploy is made
        @param overmind - deployer of the contract
    */
    fun init_module(overmind: &signer) {
        // TODO: Create a resource account using SEED const
        let (resource_account_signer, resource_account_signer_cap) = account::create_resource_account(overmind, SEED);

        // TODO: Register the resource account with AptosCoin
        coin::register<AptosCoin>(&resource_account_signer);

        // TODO: Call `check_if_account_has_enough_aptos_coins` function
        check_if_account_has_enough_aptos_coins(signer::address_of(overmind), PRIZE);

        // TODO: Transfer `PRIZE` amount of APT from `overmind` to the resource account
        coin::transfer<AptosCoin>(overmind, signer::address_of(&resource_account_signer), PRIZE);

        // TODO: Move State instance to `overmind` address
        move_to(
            overmind, 
            State {
                cap: resource_account_signer_cap
            }
        );
    }

    /*
        Allows a player to make a guess attempt and verifies either the guess is correct or not
        @param player - signer representing a player
        @param word - a word that the player thinks is the answer
    */
    public entry fun guess_word(player: &signer, word: String) acquires State, Player {
        // TODO: Call `check_if_word_length_is_correct` function
        check_if_word_length_is_correct(&word);

        // TODO: Call `create_player_resource` function
        create_player_resource(player);

        // TODO: Call `check_if_player_has_not_reached_attempts_limit_yet` function
        let player_resource = borrow_global_mut<Player>(signer::address_of(player));
        check_if_player_has_not_reached_attempts_limit_yet(player_resource);

        // TODO: Check if SHA3_256 hash of `word` is the same as `ANSWER_HASH` and:
        //      1) Call `submit_correct_answer` function if it is
        //      2) Call `add_guess_to_attempts` function if it's not
        if(hash::sha3_256(*string::bytes(&word)) == ANSWER_HASH) {
            submit_correct_answer(player_resource, signer::address_of(player));
        } else {
            add_guess_to_attempts(player_resource, &signer::address_of(player), word);
        };

        // TODO: Check if length of Player's `attempts` field equals to `ATTEMPTS_LIMIT` and change Player's
        //      `word_guessed` field's value to option::some(false) if it does
        if(simple_map::length<u8, SimpleMap<vector<u8>, bool>>(&player_resource.attempts) == ATTEMPTS_LIMIT) {
            player_resource.word_guessed = option::some(false);
        }
    }

    /*
        Returns attempts made by a player
        @param player_address - address of the player
        @return - SimpleMap instance holding data about the player's made attempts
    */
    #[view]
    public fun get_guess_attempts(player_address: address): SimpleMap<u8, SimpleMap<vector<u8>, bool>> acquires Player {
        // TODO: Check if Player resource exists under `player_address` address and:
        //      1) Return an empty instance of SimpleMap if it does not exist
        //      2) Return Player's `attempts` field if it does exist
        if(exists<Player>(player_address)) {
            let player_resource = borrow_global<Player>(player_address);
            player_resource.attempts
        } else {
            simple_map::create<u8, SimpleMap<vector<u8>, bool>>()
        }
    }

    //==============================================================================================
    // Helper functions
    //==============================================================================================

    /*
        Creates and moves a new instance of Player to `player` address
        @param player - signer representing a player
    */
    inline fun create_player_resource(player: &signer) {
        // TODO: Check if Player resource exists under `player` address and move it to that address if it does not exist
        if(!exists<Player>(signer::address_of(player))) {
            move_to(
                player, 
                Player {
                    attempts: simple_map::create<u8, SimpleMap<vector<u8>, bool>>(),
                    word_guessed: option::none(),
                    guess_word_attempt_events: account::new_event_handle<GuessWordAttemptEvent>(player),
                    submit_correct_answer_events: account::new_event_handle<SubmitCorrectAnswerEvent>(player)
                }
            );
        }
    }

    /*
        Transfers `PRIZE` amount of APT to `player_address` address and changes Player's `word_guessed` field's value
        to option::some(true)
        @param player_resource - Player resource instance
        @param player_address - address associated with `player_resource` Player instance
    */
    inline fun submit_correct_answer(player_resource: &mut Player, player_address: address) {
        // TODO: Transfer `PRIZE` amount of APT from the resource account to `player_address` address
        let existing_state = borrow_global_mut<State>(@overmind);
        let resource_account_signer = account::create_signer_with_capability(&existing_state.cap);
        coin::transfer<AptosCoin>(&resource_account_signer, player_address, PRIZE);

        // TODO: Change `word_guessed` field's value to option::some(true)
        player_resource.word_guessed = option::some(true);

        // TODO: Emit `SubmitCorrectAnswerEvent` event
        let submit_correct_answer_event_instance = SubmitCorrectAnswerEvent {
            attempt: simple_map::length<u8, SimpleMap<vector<u8>, bool>>(&player_resource.attempts),
            event_creation_timestamp_seconds: timestamp::now_seconds()
        };
        event::emit_event(&mut player_resource.submit_correct_answer_events, submit_correct_answer_event_instance);
    }

    /*
        Checks each letter of `word` and validates either a letter is correct or not and adds the result to the Player
        resource.
        @param player_resource - Player resource instance
        @param player_address - address associated with `player_resource`
        @param word - word provided to `guess_word` function by the player
    */
    inline fun add_guess_to_attempts(player_resource: &mut Player, player_address: &address, word: String) {
        // TODO: Create an instance of SimpleMap
        let letter_correctness = simple_map::create<vector<u8>, bool>();

        // TODO: Get current timestamp
        let current_timestamp = timestamp::now_seconds();

        // TODO: Iterate through the `word` and for each letter:
        //      1) Compare a SHA3_256 hash of the letter with output of `get_letter_hash` function and save the result
        //          in a variable
        //      2) Create a SHA3_256 hash of composition of the letter, the letter's position, `player_address`
        //          and current timestamp.
        //      3) Add the hash and the result to the instance of SimpleMap created previously
        let word_letters = *string::bytes(&word);
        let index = 0;

        while(index < vector::length(&word_letters)) {
            let current_letter = vector::borrow(&word_letters, index);

            let hashed_letter = vector::empty<u8>();
            vector::push_back(&mut hashed_letter, *current_letter);

            let current_letter_correctness = hash::sha3_256(hashed_letter) == get_letter_hash(index);

            let composition = vector::empty<u8>();
            vector::push_back(&mut composition, *current_letter);
            vector::push_back(&mut composition, (index as u8));
            vector::append(&mut composition, bcs::to_bytes(player_address));
            vector::append(&mut composition, bcs::to_bytes(&current_timestamp));
            
            simple_map::add<vector<u8>, bool>(&mut letter_correctness, hash::sha3_256(composition), current_letter_correctness);
            index = index + 1;
        };

        // TODO: Get current attempt (length of `attempts` SimpleMap of `player_resource`)
        let current_attemt = (simple_map::length(&player_resource.attempts) as u8);

        // TODO: Add the attempt and the SimpleMap instance created at the beginning of this function to
        //      `attempts` SimpleMap of `player_resource`
        simple_map::add<u8, SimpleMap<vector<u8>, bool>>(&mut player_resource.attempts, current_attemt, letter_correctness);

        // TODO: Emit `GuessWordAttemptEvent` event
        let guess_word_attempt_event_instance = GuessWordAttemptEvent {
            attempt: (simple_map::length(&player_resource.attempts) as u8),
            word: word,
            letter_correctness: letter_correctness,
            event_creation_timestamp_seconds: timestamp::now_seconds()
        };
        event::emit_event(&mut player_resource.guess_word_attempt_events, guess_word_attempt_event_instance);
    }

    /*
        Returns hash of a letter depending on provided index
        @param index - index of the desired letter
        @return - hash of the letter
    */
    inline fun get_letter_hash(index: u64): vector<u8> {
        // TODO: Return appropriate const located at the beginning of the file depending on provided `index` parameter
        //      (should start with 0 and end with 7). Abort with ELetterIndexOutOfBounds code if the `index` is not from
        //      a range of 0 (inclusive) to 7 (inclusive)
        let letter_hash = vector::empty<u8>();

        if(index >= 0 && index <= 7){
            if(index == 0) {
                letter_hash = FIRST_LETTER_HASH;
            } else if(index == 1) {
                letter_hash = SECOND_LETTER_HASH;
            } else if(index == 2) {
                letter_hash = THIRD_LETTER_HASH;
            } else if(index == 3) {
                letter_hash = FOURTH_LETTER_HASH;
            } else if(index == 4) {
                letter_hash = FIFTH_LETTER_HASH;
            } else if(index == 5) {
                letter_hash = SIXTH_LETTER_HASH;
            } else if(index == 6) {
                letter_hash = SEVENTH_LETTER_HASH;
            } else if(index == 7) {
                letter_hash = EIGHTH_LETTER_HASH;
            };
        } else {
            abort ELetterIndexOutOfBounds
        };

        letter_hash
    }

    //==============================================================================================
    // Validation functions
    //==============================================================================================

    inline fun check_if_account_has_enough_aptos_coins(account: address, apt_amount: u64) {
        // TODO: Assert that `account` balance of APT equals or is greater than `apt_amount`
        //      (use EInsufficientAptBalance error code)
        assert!(coin::balance<AptosCoin>(account) >= apt_amount, EInsufficientAptBalance);
    }

    inline fun check_if_player_has_not_reached_attempts_limit_yet(player_resource: &Player) {
        // TODO: Assert that length of `attempts` field of `player_resource` is smaller than `ATTEMPTS_LIMIT`
        //      (use EAttemptsLimitReached error code)
        assert!(simple_map::length<u8, SimpleMap<vector<u8>, bool>>(&player_resource.attempts) < ATTEMPTS_LIMIT, EAttemptsLimitReached);
    }

    inline fun check_if_word_length_is_correct(word: &String) {
        // TODO: Assert that length of `word` equals `ANSWER_LENGTH` (use EInccorectWordLength error code)
        assert!(string::length(word) == ANSWER_LENGTH, EInccorectWordLength);
    }

    //================================================================================================
    // Tests -- DO NOT EDIT
    //================================================================================================

    #[test_only]
    fun destroy_player_resource(player_resource: Player) {
        let Player {
            guess_word_attempt_events,
            submit_correct_answer_events,
            attempts: _,
            word_guessed: _
        } = player_resource;
        event::destroy_handle(guess_word_attempt_events);
        event::destroy_handle(submit_correct_answer_events);
    }

    #[test]
    fun test_init_module() acquires State {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        let (burn_cap, mint_cap) =
            aptos_coin::initialize_for_test(&aptos_framework);

        let overmind = account::create_account_for_test(@overmind);
        coin::register<AptosCoin>(&overmind);
        aptos_coin::mint(&aptos_framework, @overmind, PRIZE);
        init_module(&overmind);

        let state = borrow_global<State>(@overmind);
        let resource_account_address = account::create_resource_address(&@overmind, SEED);
        assert!(&state.cap == &account::create_test_signer_cap(resource_account_address), 0);
        assert!(coin::is_account_registered<AptosCoin>(resource_account_address), 1);
        assert!(coin::balance<AptosCoin>(@overmind) == 0, 2);
        assert!(coin::balance<AptosCoin>(resource_account_address) == PRIZE, 3);

        coin::destroy_mint_cap(mint_cap);
        coin::destroy_burn_cap(burn_cap);
    }

    #[test]
    #[expected_failure(abort_code = 0, location = Self)]
    fun test_init_module_insufficient_apt_balance() {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        let (burn_cap, mint_cap) =
            aptos_coin::initialize_for_test(&aptos_framework);

        let overmind = account::create_account_for_test(@overmind);
        coin::register<AptosCoin>(&overmind);
        aptos_coin::mint(&aptos_framework, @overmind, 4732843);
        init_module(&overmind);

        coin::destroy_mint_cap(mint_cap);
        coin::destroy_burn_cap(burn_cap);
    }

    #[test]
    fun test_get_guess_attempts() acquires Player {
        let guess_attempts = get_guess_attempts(@0x123123123);
        assert!(simple_map::length(&guess_attempts) == 0, 0);

        let account = account::create_account_for_test(@0x123123123);
        let attempts = simple_map::create();
        move_to(&account, Player {
            attempts,
            word_guessed: option::none(),
            guess_word_attempt_events: account::new_event_handle(&account),
            submit_correct_answer_events: account::new_event_handle(&account)
        });

        let guess_attempts = get_guess_attempts(@0x123123123);
        assert!(simple_map::length(&guess_attempts) == 0, 1);

        {
            let player = borrow_global_mut<Player>(@0x123123123);
            let answers = simple_map::create();
            simple_map::add(&mut answers, vector[1, 1, 1, 1], false);
            simple_map::add(&mut player.attempts, 0, answers);
            simple_map::add(&mut player.attempts, 1, answers);
        };

        let guess_attempts = get_guess_attempts(@0x123123123);
        assert!(simple_map::length(&guess_attempts) == 2, 3);

        let first_attempts = *simple_map::borrow(&guess_attempts, &0);
        assert!(simple_map::length(&first_attempts) == 1, 4);
        assert!(simple_map::borrow(&first_attempts, &vector[1, 1, 1, 1]) == &false, 5);

        let second_attempts = *simple_map::borrow(&guess_attempts, &1);
        assert!(simple_map::length(&second_attempts) == 1, 6);
        assert!(simple_map::borrow(&second_attempts, &vector[1, 1, 1, 1]) == &false, 7);
    }

    #[test]
    fun test_create_player_resource() acquires Player {
        let player_address = @0x12031230;
        let player = account::create_account_for_test(player_address);
        create_player_resource(&player);

        assert!(exists<Player>(player_address), 0);

        let player_resource = borrow_global<Player>(player_address);
        assert!(simple_map::length(&player_resource.attempts) == 0, 1);
        assert!(option::is_none(&player_resource.word_guessed), 2);
        assert!(event::counter(&player_resource.guess_word_attempt_events) == 0, 3);
        assert!(event::counter(&player_resource.submit_correct_answer_events) == 0, 4);
        assert!(
            guid::creator_address(event::guid(&player_resource.guess_word_attempt_events)) == player_address,
        5
        );
        assert!(
            guid::creator_address(
                event::guid(&player_resource.submit_correct_answer_events)
            ) == player_address,
            6
        );

        create_player_resource(&player);

        assert!(exists<Player>(player_address), 7);

        let player_resource = borrow_global<Player>(player_address);
        assert!(simple_map::length(&player_resource.attempts) == 0, 8);
        assert!(option::is_none(&player_resource.word_guessed), 9);
        assert!(event::counter(&player_resource.guess_word_attempt_events) == 0, 10);
        assert!(event::counter(&player_resource.submit_correct_answer_events) == 0, 11);
        assert!(
            guid::creator_address(event::guid(&player_resource.guess_word_attempt_events)) == player_address,
            12
        );
        assert!(
            guid::creator_address(
                event::guid(&player_resource.submit_correct_answer_events)
            ) == player_address,
            13
        );
    }

    #[test]
    fun test_submit_correct_answer() acquires State {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        let (burn_cap, mint_cap) =
            aptos_coin::initialize_for_test(&aptos_framework);
        timestamp::set_time_has_started_for_testing(&aptos_framework);

        let overmind = account::create_account_for_test(@overmind);
        coin::register<AptosCoin>(&overmind);
        aptos_coin::mint(&aptos_framework, @overmind, PRIZE);
        init_module(&overmind);

        let player_address = @0xACE;
        let player = account::create_account_for_test(player_address);
        let player_resource = Player {
            attempts: simple_map::create(),
            word_guessed: option::none(),
            submit_correct_answer_events: account::new_event_handle(&player),
            guess_word_attempt_events: account::new_event_handle(&player)
        };
        coin::register<AptosCoin>(&player);
        submit_correct_answer(&mut player_resource, player_address);

        let resource_account_address = account::create_resource_address(&@overmind, SEED);
        assert!(simple_map::length(&player_resource.attempts) == 0, 0);
        assert!(option::contains(&player_resource.word_guessed, &true), 1);
        assert!(event::counter(&player_resource.submit_correct_answer_events) == 1, 2);
        assert!(event::counter(&player_resource.guess_word_attempt_events) == 0, 3);
        assert!(
            guid::creator_address(
                event::guid(&player_resource.submit_correct_answer_events)
            ) == player_address,
            4
        );
        assert!(
            guid::creator_address(event::guid(&player_resource.guess_word_attempt_events)) == player_address,
            5
        );
        assert!(coin::balance<AptosCoin>(@overmind) == 0, 6);
        assert!(coin::balance<AptosCoin>(resource_account_address) == 0, 7);
        assert!(coin::balance<AptosCoin>(player_address) == PRIZE, 8);

        destroy_player_resource(player_resource);
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test]
    fun test_get_letter_hash() {
        assert!(get_letter_hash(0) == FIRST_LETTER_HASH, 0);
        assert!(get_letter_hash(1) == SECOND_LETTER_HASH, 1);
        assert!(get_letter_hash(2) == THIRD_LETTER_HASH, 2);
        assert!(get_letter_hash(3) == FOURTH_LETTER_HASH, 3);
        assert!(get_letter_hash(4) == FIFTH_LETTER_HASH, 4);
        assert!(get_letter_hash(5) == SIXTH_LETTER_HASH, 5);
        assert!(get_letter_hash(6) == SEVENTH_LETTER_HASH, 6);
        assert!(get_letter_hash(7) == EIGHTH_LETTER_HASH, 7);
    }

    #[test]
    #[expected_failure(abort_code = 2, location = Self)]
    fun test_get_letter_hash_out_of_bounds() {
        get_letter_hash(8);
    }

    #[test]
    fun test_add_guess_to_attempts() {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(&aptos_framework);

        let player_address = @0xACE;
        let player = account::create_account_for_test(player_address);
        let player_resource = Player {
            attempts: simple_map::create(),
            word_guessed: option::none(),
            guess_word_attempt_events: account::new_event_handle(&player),
            submit_correct_answer_events: account::new_event_handle(&player)
        };
        let word = string::utf8(b"UHAEKIHF");
        add_guess_to_attempts(&mut player_resource, &player_address, word);

        assert!(simple_map::length(&player_resource.attempts) == 1, 0);
        assert!(option::is_none(&player_resource.word_guessed), 1);
        assert!(event::counter(&player_resource.guess_word_attempt_events) == 1, 2);
        assert!(event::counter(&player_resource.submit_correct_answer_events) == 0, 3);
        assert!(
            guid::creator_address(event::guid(&player_resource.guess_word_attempt_events)) == player_address,
            4
        );
        assert!(
            guid::creator_address(
                event::guid(&player_resource.submit_correct_answer_events)
            ) == player_address,
            5
        );

        let attempt = *simple_map::borrow(&player_resource.attempts, &0);
        assert!(simple_map::length(&attempt) == 8, 0);

        let attempt_values = simple_map::values(&attempt);
        assert!(*vector::borrow(&attempt_values, 0) == false, 6);
        assert!(*vector::borrow(&attempt_values, 1) == false, 7);
        assert!(*vector::borrow(&attempt_values, 2) == false, 8);
        assert!(*vector::borrow(&attempt_values, 3) == false, 9);
        assert!(*vector::borrow(&attempt_values, 4) == false, 10);
        assert!(*vector::borrow(&attempt_values, 5) == true, 11);
        assert!(*vector::borrow(&attempt_values, 6) == false, 12);
        assert!(*vector::borrow(&attempt_values, 7) == false, 13);

        add_guess_to_attempts(&mut player_resource, &player_address, word);
        assert!(simple_map::length(&player_resource.attempts) == 2, 14);
        assert!(simple_map::contains_key(&player_resource.attempts, &1), 15);

        destroy_player_resource(player_resource);
    }

    #[test]
    fun test_guess_word() acquires State, Player {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        let (burn_cap, mint_cap)
            = aptos_coin::initialize_for_test(&aptos_framework);
        timestamp::set_time_has_started_for_testing(&aptos_framework);

        let overmind = account::create_account_for_test(@overmind);
        coin::register<AptosCoin>(&overmind);
        aptos_coin::mint(&aptos_framework, @overmind, PRIZE);
        init_module(&overmind);

        let player_address = @0xACE;
        let player = account::create_account_for_test(player_address);
        let word = string::utf8(b"UHAEKIHF");
        guess_word(&player, word);

        {
            let player_resource = borrow_global<Player>(player_address);
            assert!(simple_map::length(&player_resource.attempts) == 1, 0);
            assert!(option::is_none(&player_resource.word_guessed), 1);
            assert!(event::counter(&player_resource.guess_word_attempt_events) == 1, 2);
            assert!(event::counter(&player_resource.submit_correct_answer_events) == 0, 3);
            assert!(
                guid::creator_address(event::guid(&player_resource.guess_word_attempt_events)) == player_address,
                4
            );
            assert!(
                guid::creator_address(
                    event::guid(&player_resource.submit_correct_answer_events)
                ) == player_address,
                5
            );

            let first_attempt = simple_map::borrow(&player_resource.attempts, &0);
            let first_attempt_values = simple_map::values(first_attempt);
            assert!(vector::borrow(&first_attempt_values, 0) == &false, 6);
            assert!(vector::borrow(&first_attempt_values, 1) == &false, 7);
            assert!(vector::borrow(&first_attempt_values, 2) == &false, 8);
            assert!(vector::borrow(&first_attempt_values, 3) == &false, 9);
            assert!(vector::borrow(&first_attempt_values, 4) == &false, 10);
            assert!(vector::borrow(&first_attempt_values, 5) == &true, 11);
            assert!(vector::borrow(&first_attempt_values, 6) == &false, 12);
            assert!(vector::borrow(&first_attempt_values, 7) == &false, 13);
        };

        guess_word(&player, word);
        guess_word(&player, word);
        guess_word(&player, word);
        guess_word(&player, word);
        guess_word(&player, word);

        let player_resource = borrow_global<Player>(player_address);
        assert!(simple_map::length(&player_resource.attempts) == 6, 14);
        assert!(option::contains(&player_resource.word_guessed, &false), 15);

        coin::destroy_mint_cap(mint_cap);
        coin::destroy_burn_cap(burn_cap);
    }

    #[test]
    #[expected_failure(abort_code = 3, location = Self)]
    fun test_guess_word_check_if_word_length_is_correct_too_short() acquires State, Player {
        let player = account::create_account_for_test(@0xACE);
        let word = string::utf8(b"UDSA");
        guess_word(&player, word);
    }

    #[test]
    #[expected_failure(abort_code = 3, location = Self)]
    fun test_guess_word_check_if_word_length_is_correct_too_long() acquires State, Player {
        let player = account::create_account_for_test(@0xACE);
        let word = string::utf8(b"UDSAIOJFDSUDS");
        guess_word(&player, word);
    }

    #[test]
    #[expected_failure(abort_code = 1, location = Self)]
    fun test_guess_word_check_if_player_has_not_reached_attempts_limit_yet() acquires State, Player {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(&aptos_framework);

        let player_address = @0xACE;
        let player = account::create_account_for_test(player_address);
        let word = string::utf8(b"UHAEKIHF");
        guess_word(&player, word);
        guess_word(&player, word);
        guess_word(&player, word);
        guess_word(&player, word);
        guess_word(&player, word);
        guess_word(&player, word);
        guess_word(&player, word);
    }
}
