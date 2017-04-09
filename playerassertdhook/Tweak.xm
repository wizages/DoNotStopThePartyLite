%hookf(int, BSAuditTokenTaskHasEntitlement, id connection, NSString *entitlement) {
	if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
		return true;
	}

	return %orig;
}

%ctor {
	void *BSAuditTokenTaskHasEntitlement = MSFindSymbol(NULL, "_BSAuditTokenTaskHasEntitlement");
	%init;
}