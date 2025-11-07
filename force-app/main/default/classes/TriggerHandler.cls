@SuppressWarnings('PMD.ExcessivePublicCount, PMD.CyclomaticComplexity, PMD.FieldDeclarationsShouldBeAtStart, PMD.EmptyStatementBlock')
public virtual class TriggerHandler {
	@TestVisible
	private static Map<String, LoopCount> loopCountMap;

	@TestVisible
	private static Set<String> bypassedHandlers;

	@TestVisible
	private static Boolean globalBypass;

	@TestVisible
	private static Boolean showLimits;

	@TestVisible
	private static Boolean showDebug;

	@TestVisible
	private System.TriggerOperation triggerEvent;

	@TestVisible
	private Boolean isTriggerExecuting;

	@TestVisible
	private static final String BYPASS_ALL_ALIAS = 'BypassAll';

	static {
		loopCountMap = new Map<String, LoopCount>();
		bypassedHandlers = new Set<String>();
		globalBypass = false;
		showLimits = false;
		showDebug = false;
	}

	public TriggerHandler() {
		this.setTriggerContext();
	}

	public TriggerHandler(String handlerName) {
		this.handlerName = handlerName;
		this.setTriggerContext();
	}

	public void run() {
		if (!validateRun()) {
			return;
		}

		if (!incrementCheckLoopCount()) {
			return;
		}

		if (showDebug) {
			System.debug(LoggingLevel.DEBUG, String.format('Entering {0}, fired {1}', new List<String>{ getHandlerName(), this.triggerEvent + '' }));
		}

		switch on this.triggerEvent {
			when BEFORE_INSERT {
				this.beforeInsert();
			}
			when BEFORE_UPDATE {
				this.beforeUpdate();
			}
			when BEFORE_DELETE {
				this.beforeDelete();
			}
			when AFTER_INSERT {
				this.afterInsert();
			}
			when AFTER_UPDATE {
				this.afterUpdate();
			}
			when AFTER_DELETE {
				this.afterDelete();
			}
			when AFTER_UNDELETE {
				this.afterUndelete();
			}
		}
		this.andFinally();

		if (showLimits) {
			System.debug(
				LoggingLevel.DEBUG,
				String.format(
					'{0} on {1} ({2}/{3} queries) and ({4}/{5} DML calls)',
					new List<String>{
						this.triggerEvent + '',
						getHandlerName(),
						Limits.getQueries() + '',
						Limits.getLimitQueries() + '',
						Limits.getDmlStatements() + '',
						Limits.getLimitDmlStatements() + ''
					}
				)
			);
		}
		if (showDebug) {
			System.debug(LoggingLevel.DEBUG, String.format('Exiting {0}, fired {1}', new List<String>{ getHandlerName(), this.triggerEvent + '' }));
		}
	}

	public TriggerHandler setMaxLoopCount(Integer max) {
		String handlerName = getHandlerName();
		if (!TriggerHandler.loopCountMap.containsKey(handlerName)) {
			TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
		} else {
			TriggerHandler.loopCountMap.get(handlerName).setMax(max);
		}
		return this;
	}

	public void clearMaxLoopCount() {
		this.setMaxLoopCount(-1);
	}

	public static void bypass(String handlerName) {
		TriggerHandler.bypassedHandlers.add(handlerName);
	}

	public static void bypass(Type handlerType) {
		TriggerHandler.bypass(handlerType.getName());
	}

	public static void bypass(List<String> handlerNames) {
		TriggerHandler.bypassedHandlers.addAll(handlerNames);
	}

	public static void bypassAll() {
		TriggerHandler.bypassedHandlers.clear();
		globalBypass = true;
	}

	public static void clearBypass(String handlerName) {
		if (TriggerHandler.bypassedHandlers.contains(handlerName)) {
			TriggerHandler.bypassedHandlers.remove(handlerName);
		}
	}

	public static void clearBypass(Type handlerType) {
		TriggerHandler.clearBypass(handlerType.getName());
	}

	public static void clearBypass(List<String> handlerNames) {
		for (String s : handlerNames) {
			clearBypass(s);
		}
	}

	public static Boolean isBypassed(String handlerName) {
		return (globalBypass || TriggerHandler.bypassedHandlers.contains(handlerName));
	}

	public static Boolean isBypassed(Type handlerType) {
		return (globalBypass || TriggerHandler.bypassedHandlers.contains(handlerType.getName()));
	}

	public static List<String> bypassList() {
		List<String> bypasses = new List<String>(TriggerHandler.bypassedHandlers);
		bypasses.sort();
		if (globalBypass) {
			bypasses.add(BYPASS_ALL_ALIAS);
		}

		return bypasses;
	}

	public static Set<String> bypassSet() {
		Set<String> bypasses = new Set<String>(TriggerHandler.bypassedHandlers);
		if (globalBypass) {
			bypasses.add(BYPASS_ALL_ALIAS);
		}

		return bypasses;
	}

	public static void clearAllBypasses() {
		clearGlobalBypass();
		clearBypassList();
	}

	public static void clearGlobalBypass() {
		globalBypass = false;
	}

	public static void clearBypassList() {
		TriggerHandler.bypassedHandlers.clear();
	}

	public static void setBypass(String handlerName, Boolean desiredValue) {
		if (globalBypass) {
			if (desiredValue == true) {
				TriggerHandler.bypass(handlerName);
			} else if (desiredValue == false) {
				clearGlobalBypass();
				TriggerHandler.clearBypass(handlerName);
			}
		}
		if (TriggerHandler.isBypassed(handlerName)) {
			if (desiredValue == false) {
				TriggerHandler.clearBypass(handlerName);
			}
		} else {
			if (desiredValue == true) {
				TriggerHandler.bypass(handlerName);
			}
		}
	}

	public TriggerHandler limits() {
		showLimits();
		return this;
	}

	public TriggerHandler limits(Boolean enabled) {
		showLimits(enabled);
		return this;
	}

	public static void showLimits() {
		showLimits(true);
	}

	public static void showLimits(Boolean enabled) {
		if (enabled) {
			showLimits = true;
		} else {
			showLimits = false;
		}
	}

	public TriggerHandler debug() {
		showDebug();
		return this;
	}

	public TriggerHandler debug(Boolean enabled) {
		showDebug(enabled);
		return this;
	}

	public static void showDebug() {
		showDebug(true);
	}

	public static void showDebug(Boolean enabled) {
	    if (enabled) {
			showDebug = true;
		} else {
			showDebug = false;
		}
	}

	public static Integer getLoopCount(String handlerName) {
		if (TriggerHandler.loopCountMap.containsKey(handlerName)) {
			return TriggerHandler.loopCountMap.get(handlerName).getCount();
		}
		return 0;
	}

	@TestVisible
	private void setTriggerContext() {
		this.setTriggerContext(Trigger.operationType, false);
	}

	@TestVisible
	private void setTriggerContext(System.TriggerOperation opType, Boolean testMode) {
		if (!Trigger.isExecuting && !testMode) {
			this.isTriggerExecuting = false;
			return;
		} else {
			this.isTriggerExecuting = true;
		}		
		if (Trigger.isExecuting && !testMode) {
			this.triggerEvent = Trigger.operationType;
		}
		
		String context = opType?.name();

		switch on context {
			when 'BEFORE_INSERT' {
				this.triggerEvent = System.TriggerOperation.BEFORE_INSERT;
			}
			when 'BEFORE_UPDATE' {
				this.triggerEvent = System.TriggerOperation.BEFORE_UPDATE;
			}
			when 'BEFORE_DELETE' {
				this.triggerEvent = System.TriggerOperation.BEFORE_DELETE;
			}
			when 'AFTER_INSERT' {
				this.triggerEvent = System.TriggerOperation.AFTER_INSERT;
			}
			when 'AFTER_UPDATE' {
				this.triggerEvent = System.TriggerOperation.AFTER_UPDATE;
			}
			when 'AFTER_DELETE' {
				this.triggerEvent = System.TriggerOperation.AFTER_DELETE;
			}
			when 'AFTER_UNDELETE' {
				this.triggerEvent = System.TriggerOperation.AFTER_UNDELETE;
			}
			when else {
				this.isTriggerExecuting = false;
			}
		}
	}

	private Boolean incrementCheckLoopCount() {
		String handlerName = getHandlerName();
		if (TriggerHandler.loopCountMap.containsKey(handlerName)) {
			Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName).increment();
			if (exceeded) {
				if (showDebug) {
					Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
					System.debug(logginglevel.INFO, 'Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
				}
				return false;
			}
			return true;
		}
		return true;
	}

	@TestVisible
	private Boolean validateRun() {
		if (!this.isTriggerExecuting || this.triggerEvent == null) {
			throw new TriggerHandlerException(ERROR_TRIGGERCONTEXT);
		}
		return (!globalBypass && !TriggerHandler.bypassedHandlers.contains(getHandlerName()));
	}

	private String handlerName;

	@TestVisible
	private String getHandlerName() {
		if (String.isBlank(this.handlerName)) {
			this.handlerName = this.toString().substringBefore(':');
		}
		return this.handlerName;
	}

	@TestVisible
	protected virtual void beforeInsert() {
	}

	@TestVisible
	protected virtual void beforeUpdate() {
	}

	@TestVisible
	protected virtual void beforeDelete() {
	}

	@TestVisible
	protected virtual void afterInsert() {
	}

	@TestVisible
	protected virtual void afterUpdate() {
	}

	@TestVisible
	protected virtual void afterDelete() {
	}

	@TestVisible
	protected virtual void afterUndelete() {
	}

	@TestVisible
	protected virtual void andFinally() {
	}

	@TestVisible
	private class LoopCount {
		private Integer max;
		private Integer count;

		public LoopCount() {
			this.max = 5;
			this.count = 0;
		}

		public LoopCount(Integer max) {
			this.max = max;
			this.count = 0;
		}

		public Boolean increment() {
			this.count++;
			return this.exceeded();
		}

		public Boolean exceeded() {
			return this.max >= 0 && this.count > this.max;
		}

		public Integer getMax() {
			return this.max;
		}

		public Integer getCount() {
			return this.count;
		}

		public void setMax(Integer max) {
			this.max = max;
		}
	}

	public class TriggerHandlerException extends Exception {
	}

	@TestVisible
	private static final String ERROR_TRIGGERCONTEXT = 'Trigger handler called outside of Trigger execution';
}