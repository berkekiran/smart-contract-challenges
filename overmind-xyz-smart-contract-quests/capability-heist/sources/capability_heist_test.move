module overmind::capability_heist_test {
    #[test_only]
    use std::string::String;
    #[test_only]
    use aptos_std::aptos_hash;
    #[test_only]
    use std::string;
    #[test_only]
    use aptos_framework::account;
    #[test_only]
    use aptos_std::capability;
    #[test_only]
    use std::features;
    #[test_only]
    use overmind::capability_heist;

    const FLAG: vector<u8> = x"4ceaf30e4f219942dcd6f8fdbc5843c0c53fd14293c4d78256453e94785fb47fad7bfd2f6e038ac2b675453c6a6357ff4f9d68a6e671ae16999acdfc4649d924";

    #[test_only]
    struct TestCapability has drop {}

    #[test_only]
    fun answer_test_question(answer: String): bool {
        let expected = x"301bb421c971fbb7ed01dcc3a9976ce53df034022ba982b97d0f27d48c4f03883aabf7c6bc778aa7c383062f6823045a6d41b8a720afbb8a9607690f89fbe1a7";

        expected == aptos_hash::sha3_512(*string::bytes(&answer))
    }

    #[test]
    fun test_init() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);

        assert!(capability_heist::check_robber_exists(@robber), 0);

        let resource_account_address =
            account::create_resource_address(&@robber, b"CapabilityHeist");
        let resource_account_signer = account::create_signer_for_test(resource_account_address);
        capability::acquire(&resource_account_signer, &capability_heist::new_enter_bank());
        capability::acquire(&resource_account_signer, &capability_heist::new_open_vault());
        capability::acquire(&resource_account_signer, &capability_heist::new_get_keycard());
        capability::acquire(&resource_account_signer, &capability_heist::new_open_vault());
    }

    #[test]
    #[expected_failure(abort_code = 0, location = overmind::capability_heist)]
    fun test_init_access_denied() {
        let invalid_robber = account::create_account_for_test(@0xCAFE);
        capability_heist::init(&invalid_robber);
    }

    #[test]
    #[expected_failure(abort_code = 524303, location = aptos_framework::account)]
    fun test_init_already_initialized() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);
        capability_heist::init(&robber);
    }

    #[test]
    fun test_enter_bank() {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        features::change_feature_flags(
            &aptos_framework,
            vector[features::get_sha_512_and_ripemd_160_feature()],
            vector[]
        );

        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);
        capability_heist::enter_bank(&robber);

        capability::acquire(&robber, &capability_heist::new_enter_bank());
    }

    #[test]
    #[expected_failure(abort_code = 1, location = overmind::capability_heist)]
    fun test_enter_bank_robber_not_initialized() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::enter_bank(&robber);
    }

    #[test]
    fun test_take_hostage() {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        features::change_feature_flags(
            &aptos_framework,
            vector[features::get_sha_512_and_ripemd_160_feature()],
            vector[]
        );

        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);

        let resource_acccount_address =
            account::create_resource_address(&@robber, b"CapabilityHeist");
        let resource_account_signer = account::create_signer_for_test(resource_acccount_address);
        capability::delegate(
            capability::acquire(&resource_account_signer, &capability_heist::new_enter_bank()),
            &capability_heist::new_enter_bank(),
            &robber
        );

        capability_heist::take_hostage(&robber);
        capability::acquire(&robber, &capability_heist::new_take_hostage());
    }

    #[test]
    #[expected_failure(abort_code = 1, location = overmind::capability_heist)]
    fun test_take_hostage_robber_not_initialized() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::take_hostage(&robber);
    }

    #[test]
    #[expected_failure(abort_code = 393218, location = aptos_std::capability)]
    fun test_take_hostage_no_enter_bank_capability() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);
        capability_heist::take_hostage(&robber);
    }

    #[test]
    fun test_get_keycard() {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        features::change_feature_flags(
            &aptos_framework,
            vector[features::get_sha_512_and_ripemd_160_feature()],
            vector[]
        );

        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);

        let resource_acccount_address =
            account::create_resource_address(&@robber, b"CapabilityHeist");
        let resource_account_signer = account::create_signer_for_test(resource_acccount_address);
        capability::delegate(
            capability::acquire(&resource_account_signer, &capability_heist::new_enter_bank()),
            &capability_heist::new_enter_bank(),
            &robber
        );
        capability::delegate(
            capability::acquire(&resource_account_signer, &capability_heist::new_take_hostage()),
            &capability_heist::new_take_hostage(),
            &robber
        );

        capability_heist::get_keycard(&robber);
        capability::acquire(&robber, &capability_heist::new_get_keycard());
    }

    #[test]
    #[expected_failure(abort_code = 1, location = overmind::capability_heist)]
    fun test_get_keycard_robber_not_initialized() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::get_keycard(&robber);
    }

    #[test]
    #[expected_failure(abort_code = 393218, location = aptos_std::capability)]
    fun test_get_keycard_no_enter_bank_capability() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);
        capability_heist::get_keycard(&robber);
    }

    #[test]
    #[expected_failure(abort_code = 393218, location = aptos_std::capability)]
    fun test_get_keycard_no_take_hostage_capability() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);

        let resource_acccount_address =
            account::create_resource_address(&@robber, b"CapabilityHeist");
        let resource_account_signer = account::create_signer_for_test(resource_acccount_address);
        capability::delegate(
            capability::acquire(&resource_account_signer, &capability_heist::new_enter_bank()),
            &capability_heist::new_enter_bank(),
            &robber
        );

        capability_heist::get_keycard(&robber);
    }

    #[test]
    fun test_open_vault() {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        features::change_feature_flags(
            &aptos_framework,
            vector[features::get_sha_512_and_ripemd_160_feature()],
            vector[]
        );

        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);

        let resource_acccount_address =
            account::create_resource_address(&@robber, b"CapabilityHeist");
        let resource_account_signer = account::create_signer_for_test(resource_acccount_address);
        capability::delegate(
            capability::acquire(&resource_account_signer, &capability_heist::new_enter_bank()),
            &capability_heist::new_enter_bank(),
            &robber
        );
        capability::delegate(
            capability::acquire(&resource_account_signer, &capability_heist::new_take_hostage()),
            &capability_heist::new_take_hostage(),
            &robber
        );
        capability::delegate(
            capability::acquire(&resource_account_signer, &capability_heist::new_get_keycard()),
            &capability_heist::new_get_keycard(),
            &robber
        );

        capability_heist::open_vault(&robber);
        capability::acquire(&robber, &capability_heist::new_open_vault());
    }

    #[test]
    #[expected_failure(abort_code = 1, location = overmind::capability_heist)]
    fun test_open_vault_robber_not_initialized() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::open_vault(&robber);
    }

    #[test]
    #[expected_failure(abort_code = 393218, location = aptos_std::capability)]
    fun test_open_vault_no_enter_bank_capability() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);
        capability_heist::open_vault(&robber);
    }

    #[test]
    #[expected_failure(abort_code = 393218, location = aptos_std::capability)]
    fun test_open_vault_no_take_hostage_capability() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);

        let resource_acccount_address =
            account::create_resource_address(&@robber, b"CapabilityHeist");
        let resource_account_signer = account::create_signer_for_test(resource_acccount_address);
        capability::delegate(
            capability::acquire(&resource_account_signer, &capability_heist::new_enter_bank()),
            &capability_heist::new_enter_bank(),
            &robber
        );

        capability_heist::open_vault(&robber);
    }

    #[test]
    #[expected_failure(abort_code = 393218, location = aptos_std::capability)]
    fun test_open_vault_no_get_keycard_capability() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);

        let resource_acccount_address =
            account::create_resource_address(&@robber, b"CapabilityHeist");
        let resource_account_signer = account::create_signer_for_test(resource_acccount_address);
        capability::delegate(
            capability::acquire(&resource_account_signer, &capability_heist::new_enter_bank()),
            &capability_heist::new_enter_bank(),
            &robber
        );
        capability::delegate(
            capability::acquire(&resource_account_signer, &capability_heist::new_get_keycard()),
            &capability_heist::new_get_keycard(),
            &robber
        );

        capability_heist::open_vault(&robber);
    }

    #[test]
    fun test_all_answers_are_correct() {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        features::change_feature_flags(
            &aptos_framework,
            vector[features::get_sha_512_and_ripemd_160_feature()],
            vector[]
        );

        let user_flag = capability_heist::get_flag();
        assert!(user_flag == FLAG, 0);
    }

    #[test]
    fun test_delegate_capability() {
        let robber = account::create_account_for_test(@robber);
        capability_heist::init(&robber);

        {
            let resource_account_address =
                account::create_resource_address(&@robber, b"CapabilityHeist");
            let resource_account_signer = account::create_signer_for_test(resource_account_address);
            capability::create(&resource_account_signer, &TestCapability {});
        };

        capability_heist::delegate_capability(&robber, &TestCapability {});
        capability::acquire(&robber, &TestCapability {});
    }

    #[test]
    fun test_answer_test_question() {
        let aptos_framework = account::create_account_for_test(@aptos_framework);
        features::change_feature_flags(&aptos_framework, vector[features::get_sha_512_and_ripemd_160_feature()], vector[]);

        assert!(answer_test_question(string::utf8(b"Test")), 0);
    }
}
